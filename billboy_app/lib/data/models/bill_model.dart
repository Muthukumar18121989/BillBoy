import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/bill_entity.dart';

class BillModel extends BillEntity {
  const BillModel({
    required super.id,
    required super.userId,
    required super.productName,
    required super.category,
    required super.purchaseDate,
    super.billNumber,
    super.warrantyMonths,
    super.warrantyEndDate,
    required super.purchaseAmount,
    super.taxAmount,
    super.currentValue,
    super.serialNumber,
    super.imeiNumber,
    super.modelNumber,
    super.brandName,
    super.gstNumber,
    super.storeName,
    super.storeAddress,
    super.attachmentUrls,
    super.thumbnailUrl,
    super.ocrText,
    super.notes,
    required super.warrantyStatus,
    required super.createdAt,
    required super.updatedAt,
  });

  factory BillModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BillModel(
      id: doc.id,
      userId: data['userId'] as String,
      productName: data['productName'] as String,
      category: data['category'] as String,
      purchaseDate: (data['purchaseDate'] as Timestamp).toDate(),
      billNumber: data['billNumber'] as String?,
      warrantyMonths: data['warrantyMonths'] as int?,
      warrantyEndDate: data['warrantyEndDate'] != null
          ? (data['warrantyEndDate'] as Timestamp).toDate()
          : null,
      purchaseAmount: (data['purchaseAmount'] as num).toDouble(),
      taxAmount: data['taxAmount'] != null ? (data['taxAmount'] as num).toDouble() : null,
      currentValue: data['currentValue'] != null ? (data['currentValue'] as num).toDouble() : null,
      serialNumber: data['serialNumber'] as String?,
      imeiNumber: data['imeiNumber'] as String?,
      modelNumber: data['modelNumber'] as String?,
      brandName: data['brandName'] as String?,
      gstNumber: data['gstNumber'] as String?,
      storeName: data['storeName'] as String?,
      storeAddress: data['storeAddress'] as String?,
      attachmentUrls: List<String>.from(data['attachmentUrls'] ?? []),
      thumbnailUrl: data['thumbnailUrl'] as String?,
      ocrText: data['ocrText'] as String?,
      notes: data['notes'] as String?,
      warrantyStatus: WarrantyStatus.values.firstWhere(
        (e) => e.name == (data['warrantyStatus'] as String? ?? 'noWarranty'),
        orElse: () => WarrantyStatus.noWarranty,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'productName': productName,
      'category': category,
      'purchaseDate': Timestamp.fromDate(purchaseDate),
      'billNumber': billNumber,
      'warrantyMonths': warrantyMonths,
      'warrantyEndDate': warrantyEndDate != null ? Timestamp.fromDate(warrantyEndDate!) : null,
      'purchaseAmount': purchaseAmount,
      'taxAmount': taxAmount,
      'currentValue': currentValue,
      'serialNumber': serialNumber,
      'imeiNumber': imeiNumber,
      'modelNumber': modelNumber,
      'brandName': brandName,
      'gstNumber': gstNumber,
      'storeName': storeName,
      'storeAddress': storeAddress,
      'attachmentUrls': attachmentUrls,
      'thumbnailUrl': thumbnailUrl,
      'ocrText': ocrText,
      'notes': notes,
      'warrantyStatus': warrantyStatus.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory BillModel.fromEntity(BillEntity entity) {
    return BillModel(
      id: entity.id,
      userId: entity.userId,
      productName: entity.productName,
      category: entity.category,
      purchaseDate: entity.purchaseDate,
      billNumber: entity.billNumber,
      warrantyMonths: entity.warrantyMonths,
      warrantyEndDate: entity.warrantyEndDate,
      purchaseAmount: entity.purchaseAmount,
      taxAmount: entity.taxAmount,
      currentValue: entity.currentValue,
      serialNumber: entity.serialNumber,
      imeiNumber: entity.imeiNumber,
      modelNumber: entity.modelNumber,
      brandName: entity.brandName,
      gstNumber: entity.gstNumber,
      storeName: entity.storeName,
      storeAddress: entity.storeAddress,
      attachmentUrls: entity.attachmentUrls,
      thumbnailUrl: entity.thumbnailUrl,
      ocrText: entity.ocrText,
      notes: entity.notes,
      warrantyStatus: entity.warrantyStatus,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
