import '../../core/errors/failures.dart';
import '../../core/utils/either.dart';
import '../entities/bill_entity.dart';

class BillFilter {
  final String? category;
  final String? warrantyStatus;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? minAmount;
  final double? maxAmount;
  final String? searchQuery;
  final String? sortBy;
  final bool sortAscending;

  const BillFilter({
    this.category,
    this.warrantyStatus,
    this.startDate,
    this.endDate,
    this.minAmount,
    this.maxAmount,
    this.searchQuery,
    this.sortBy,
    this.sortAscending = false,
  });
}

abstract class BillRepository {
  Future<Either<Failure, List<BillEntity>>> getBills({
    int page = 1,
    int pageSize = 20,
    BillFilter? filter,
  });

  Future<Either<Failure, BillEntity>> getBillById(String id);

  Future<Either<Failure, BillEntity>> createBill(BillEntity bill);

  Future<Either<Failure, BillEntity>> updateBill(BillEntity bill);

  Future<Either<Failure, void>> deleteBill(String id);

  Future<Either<Failure, List<BillEntity>>> searchBills(String query);

  Future<Either<Failure, OcrExtractedData>> extractBillFromImage(String imagePath);

  Future<Either<Failure, OcrExtractedData>> extractBillFromPdf(String pdfPath);

  Future<Either<Failure, String>> uploadAttachment(String filePath, String billId);

  Future<Either<Failure, void>> deleteAttachment(String attachmentUrl);

  Future<Either<Failure, Map<String, dynamic>>> getDashboardStats();

  Future<Either<Failure, List<BillEntity>>> getExpiringWarranties(int days);

  Future<Either<Failure, void>> exportToCsv(List<BillEntity> bills, String filePath);

  Future<Either<Failure, void>> exportToPdf(List<BillEntity> bills, String filePath);
}
