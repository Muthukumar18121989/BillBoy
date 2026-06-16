import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/exceptions.dart';
import '../../../domain/entities/bill_entity.dart';
import '../../models/bill_model.dart';

abstract class BillLocalDataSource {
  Future<List<BillEntity>> getCachedBills();
  Future<void> cacheBills(List<BillEntity> bills);
  Future<void> clearCache();
}

class BillLocalDataSourceImpl implements BillLocalDataSource {
  final SharedPreferences _prefs;

  BillLocalDataSourceImpl(this._prefs);

  @override
  Future<List<BillEntity>> getCachedBills() async {
    try {
      final jsonStr = _prefs.getString(AppConstants.billsBox);
      if (jsonStr == null) return [];
      final list = json.decode(jsonStr) as List;
      return list.map((item) => _mapToEntity(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> cacheBills(List<BillEntity> bills) async {
    try {
      final list = bills.map(_entityToMap).toList();
      await _prefs.setString(AppConstants.billsBox, json.encode(list));
    } catch (e) {
      throw CacheException('Failed to cache bills: $e');
    }
  }

  @override
  Future<void> clearCache() async {
    await _prefs.remove(AppConstants.billsBox);
  }

  Map<String, dynamic> _entityToMap(BillEntity bill) {
    return {
      'id': bill.id,
      'userId': bill.userId,
      'productName': bill.productName,
      'category': bill.category,
      'purchaseDate': bill.purchaseDate.toIso8601String(),
      'billNumber': bill.billNumber,
      'warrantyMonths': bill.warrantyMonths,
      'warrantyEndDate': bill.warrantyEndDate?.toIso8601String(),
      'purchaseAmount': bill.purchaseAmount,
      'taxAmount': bill.taxAmount,
      'currentValue': bill.currentValue,
      'serialNumber': bill.serialNumber,
      'imeiNumber': bill.imeiNumber,
      'modelNumber': bill.modelNumber,
      'brandName': bill.brandName,
      'gstNumber': bill.gstNumber,
      'storeName': bill.storeName,
      'storeAddress': bill.storeAddress,
      'attachmentUrls': bill.attachmentUrls,
      'thumbnailUrl': bill.thumbnailUrl,
      'notes': bill.notes,
      'warrantyStatus': bill.warrantyStatus.name,
      'createdAt': bill.createdAt.toIso8601String(),
      'updatedAt': bill.updatedAt.toIso8601String(),
    };
  }

  BillEntity _mapToEntity(Map<String, dynamic> map) {
    return BillModel(
      id: map['id'] as String,
      userId: map['userId'] as String,
      productName: map['productName'] as String,
      category: map['category'] as String,
      purchaseDate: DateTime.parse(map['purchaseDate'] as String),
      billNumber: map['billNumber'] as String?,
      warrantyMonths: map['warrantyMonths'] as int?,
      warrantyEndDate: map['warrantyEndDate'] != null
          ? DateTime.parse(map['warrantyEndDate'] as String)
          : null,
      purchaseAmount: (map['purchaseAmount'] as num).toDouble(),
      taxAmount: map['taxAmount'] != null ? (map['taxAmount'] as num).toDouble() : null,
      currentValue: map['currentValue'] != null ? (map['currentValue'] as num).toDouble() : null,
      serialNumber: map['serialNumber'] as String?,
      imeiNumber: map['imeiNumber'] as String?,
      modelNumber: map['modelNumber'] as String?,
      brandName: map['brandName'] as String?,
      gstNumber: map['gstNumber'] as String?,
      storeName: map['storeName'] as String?,
      storeAddress: map['storeAddress'] as String?,
      attachmentUrls: List<String>.from(map['attachmentUrls'] ?? []),
      thumbnailUrl: map['thumbnailUrl'] as String?,
      notes: map['notes'] as String?,
      warrantyStatus: WarrantyStatus.values.firstWhere(
        (e) => e.name == (map['warrantyStatus'] as String? ?? 'noWarranty'),
        orElse: () => WarrantyStatus.noWarranty,
      ),
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }
}
