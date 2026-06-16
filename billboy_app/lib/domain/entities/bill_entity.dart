import 'package:equatable/equatable.dart';

enum WarrantyStatus { active, expiringSoon, expired, noWarranty }

class BillEntity extends Equatable {
  final String id;
  final String userId;
  final String productName;
  final String category;
  final DateTime purchaseDate;
  final String? billNumber;
  final int? warrantyMonths;
  final DateTime? warrantyEndDate;
  final double purchaseAmount;
  final double? taxAmount;
  final double? currentValue;
  final String? serialNumber;
  final String? imeiNumber;
  final String? modelNumber;
  final String? brandName;
  final String? gstNumber;
  final String? storeName;
  final String? storeAddress;
  final List<String> attachmentUrls;
  final String? thumbnailUrl;
  final String? ocrText;
  final String? notes;
  final WarrantyStatus warrantyStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BillEntity({
    required this.id,
    required this.userId,
    required this.productName,
    required this.category,
    required this.purchaseDate,
    this.billNumber,
    this.warrantyMonths,
    this.warrantyEndDate,
    required this.purchaseAmount,
    this.taxAmount,
    this.currentValue,
    this.serialNumber,
    this.imeiNumber,
    this.modelNumber,
    this.brandName,
    this.gstNumber,
    this.storeName,
    this.storeAddress,
    this.attachmentUrls = const [],
    this.thumbnailUrl,
    this.ocrText,
    this.notes,
    required this.warrantyStatus,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get hasWarranty => warrantyMonths != null && warrantyMonths! > 0;

  int? get daysUntilWarrantyExpiry {
    if (warrantyEndDate == null) return null;
    return warrantyEndDate!.difference(DateTime.now()).inDays;
  }

  double get depreciationPercentage {
    if (currentValue == null || purchaseAmount <= 0) return 0;
    return ((purchaseAmount - currentValue!) / purchaseAmount) * 100;
  }

  double get valueLoss {
    if (currentValue == null) return 0;
    return (purchaseAmount - currentValue!).clamp(0.0, purchaseAmount);
  }

  @override
  List<Object?> get props => [id, productName, purchaseDate, purchaseAmount];
}

class OcrExtractedData extends Equatable {
  final String? productName;
  final String? category;
  final String? billNumber;
  final DateTime? purchaseDate;
  final int? warrantyMonths;
  final double? purchaseAmount;
  final double? taxAmount;
  final String? serialNumber;
  final String? imeiNumber;
  final String? modelNumber;
  final String? brandName;
  final String? storeName;
  final String? storeAddress;
  final String? gstNumber;
  final String rawText;
  final double confidence;

  const OcrExtractedData({
    this.productName,
    this.category,
    this.billNumber,
    this.purchaseDate,
    this.warrantyMonths,
    this.purchaseAmount,
    this.taxAmount,
    this.serialNumber,
    this.imeiNumber,
    this.modelNumber,
    this.brandName,
    this.storeName,
    this.storeAddress,
    this.gstNumber,
    required this.rawText,
    required this.confidence,
  });

  @override
  List<Object?> get props => [rawText, confidence];
}
