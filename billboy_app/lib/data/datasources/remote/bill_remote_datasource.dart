import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

import '../../../core/errors/exceptions.dart';
import '../../../domain/entities/bill_entity.dart';
import '../../../domain/repositories/bill_repository.dart';
import '../../models/bill_model.dart';

abstract class BillRemoteDataSource {
  Future<List<BillEntity>> getBills({int page, int pageSize, BillFilter? filter});
  Future<BillEntity> getBillById(String id);
  Future<BillEntity> createBill(BillEntity bill);
  Future<BillEntity> updateBill(BillEntity bill);
  Future<void> deleteBill(String id);
  Future<List<BillEntity>> searchBills(String query);
  Future<String> uploadAttachment(String filePath, String billId);
  Future<void> deleteAttachment(String attachmentUrl);
  Future<Map<String, dynamic>> getDashboardStats();
  Future<List<BillEntity>> getExpiringWarranties(int days);
}

class BillRemoteDataSourceImpl implements BillRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  BillRemoteDataSourceImpl(this._firestore, this._storage);

  String get _userId => FirebaseAuth.instance.currentUser?.uid ?? '';

  CollectionReference get _bills => _firestore.collection('bills');

  @override
  Future<List<BillEntity>> getBills({
    int page = 1,
    int pageSize = 20,
    BillFilter? filter,
  }) async {
    try {
      Query query = _bills.where('userId', isEqualTo: _userId);

      if (filter?.category != null) {
        query = query.where('category', isEqualTo: filter!.category);
      }
      if (filter?.warrantyStatus != null) {
        query = query.where('warrantyStatus', isEqualTo: filter!.warrantyStatus);
      }
      if (filter?.startDate != null) {
        query = query.where('purchaseDate', isGreaterThanOrEqualTo: Timestamp.fromDate(filter!.startDate!));
      }
      if (filter?.endDate != null) {
        query = query.where('purchaseDate', isLessThanOrEqualTo: Timestamp.fromDate(filter!.endDate!));
      }

      final sortField = filter?.sortBy ?? 'purchaseDate';
      query = query.orderBy(sortField, descending: !(filter?.sortAscending ?? false));

      // Firestore doesn't support offset — use limit-based pagination
      final snapshot = await query
          .limit(pageSize * page)
          .get();
      final allDocs = snapshot.docs;
      final startIndex = (page - 1) * pageSize;
      final pageDocs = startIndex < allDocs.length
          ? allDocs.sublist(startIndex, (startIndex + pageSize).clamp(0, allDocs.length))
          : <QueryDocumentSnapshot>[];

      return pageDocs.map((doc) => BillModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw ServerException('Failed to fetch bills: $e');
    }
  }

  @override
  Future<BillEntity> getBillById(String id) async {
    try {
      final doc = await _bills.doc(id).get();
      if (!doc.exists) throw ServerException('Bill not found');
      return BillModel.fromFirestore(doc);
    } catch (e) {
      throw ServerException('Failed to fetch bill: $e');
    }
  }

  @override
  Future<BillEntity> createBill(BillEntity bill) async {
    try {
      final model = BillModel.fromEntity(bill);
      await _bills.doc(bill.id).set(model.toFirestore());
      return bill;
    } catch (e) {
      throw ServerException('Failed to create bill: $e');
    }
  }

  @override
  Future<BillEntity> updateBill(BillEntity bill) async {
    try {
      final model = BillModel.fromEntity(bill);
      await _bills.doc(bill.id).update(model.toFirestore());
      return bill;
    } catch (e) {
      throw ServerException('Failed to update bill: $e');
    }
  }

  @override
  Future<void> deleteBill(String id) async {
    try {
      await _bills.doc(id).delete();
    } catch (e) {
      throw ServerException('Failed to delete bill: $e');
    }
  }

  @override
  Future<List<BillEntity>> searchBills(String query) async {
    try {
      // Firestore text search (basic — production use Algolia/Typesense)
      final snapshot = await _bills
          .where('userId', isEqualTo: _userId)
          .orderBy('productName')
          .startAt([query])
          .endAt(['$query'])
          .limit(50)
          .get();

      final results = snapshot.docs.map((doc) => BillModel.fromFirestore(doc)).toList();

      // Also search by serial, store, bill number
      if (results.length < 10) {
        final bySerial = await _bills
            .where('userId', isEqualTo: _userId)
            .where('serialNumber', isEqualTo: query)
            .get();
        results.addAll(bySerial.docs.map((d) => BillModel.fromFirestore(d)));

        final byBillNo = await _bills
            .where('userId', isEqualTo: _userId)
            .where('billNumber', isEqualTo: query)
            .get();
        results.addAll(byBillNo.docs.map((d) => BillModel.fromFirestore(d)));
      }

      final seen = <String>{};
      return results.where((b) => seen.add(b.id)).toList();
    } catch (e) {
      throw ServerException('Search failed: $e');
    }
  }

  @override
  Future<String> uploadAttachment(String filePath, String billId) async {
    try {
      final file = File(filePath);
      final fileName = path.basename(filePath);
      final ref = _storage.ref('bills/$_userId/$billId/$fileName');
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      throw StorageException('Failed to upload file: $e');
    }
  }

  @override
  Future<void> deleteAttachment(String attachmentUrl) async {
    try {
      final ref = _storage.refFromURL(attachmentUrl);
      await ref.delete();
    } catch (e) {
      throw StorageException('Failed to delete file: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final snapshot = await _bills.where('userId', isEqualTo: _userId).get();
      final bills = snapshot.docs.map((d) => BillModel.fromFirestore(d)).toList();

      final now = DateTime.now();
      double totalSpend = 0;
      int activeWarranties = 0;
      int expiredWarranties = 0;
      int upcomingExpiries = 0;
      final Map<String, double> categoryBreakdown = {};
      final Map<String, double> monthlySpending = {};
      final List<Map<String, dynamic>> expiringWarranties = [];

      for (final bill in bills) {
        totalSpend += bill.purchaseAmount;

        final cat = bill.category;
        categoryBreakdown[cat] = (categoryBreakdown[cat] ?? 0) + bill.purchaseAmount;

        final monthKey = '${bill.purchaseDate.year}-${bill.purchaseDate.month.toString().padLeft(2, '0')}';
        monthlySpending[monthKey] = (monthlySpending[monthKey] ?? 0) + bill.purchaseAmount;

        if (bill.warrantyEndDate != null) {
          if (now.isAfter(bill.warrantyEndDate!)) {
            expiredWarranties++;
          } else {
            activeWarranties++;
            final daysLeft = bill.warrantyEndDate!.difference(now).inDays;
            if (daysLeft <= 90) {
              upcomingExpiries++;
              expiringWarranties.add({
                'id': bill.id,
                'productName': bill.productName,
                'daysLeft': daysLeft,
                'warrantyEnd': bill.warrantyEndDate,
              });
            }
          }
        }
      }

      expiringWarranties.sort((a, b) => (a['daysLeft'] as int).compareTo(b['daysLeft'] as int));

      return {
        'totalProducts': bills.length,
        'totalSpend': totalSpend,
        'activeWarranties': activeWarranties,
        'expiredWarranties': expiredWarranties,
        'upcomingExpiries': upcomingExpiries,
        'categoryBreakdown': categoryBreakdown,
        'monthlySpending': monthlySpending,
        'expiringWarranties': expiringWarranties,
      };
    } catch (e) {
      throw ServerException('Failed to load dashboard stats: $e');
    }
  }

  @override
  Future<List<BillEntity>> getExpiringWarranties(int days) async {
    try {
      final now = DateTime.now();
      final cutoff = now.add(Duration(days: days));

      final snapshot = await _bills
          .where('userId', isEqualTo: _userId)
          .where('warrantyEndDate', isGreaterThan: Timestamp.fromDate(now))
          .where('warrantyEndDate', isLessThan: Timestamp.fromDate(cutoff))
          .orderBy('warrantyEndDate')
          .get();

      return snapshot.docs.map((d) => BillModel.fromFirestore(d)).toList();
    } catch (e) {
      throw ServerException('Failed to load expiring warranties: $e');
    }
  }
}
