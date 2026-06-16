import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../core/services/ocr_service.dart';
import '../../core/utils/currency_utils.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/either.dart';
import '../../domain/entities/bill_entity.dart';
import '../../domain/repositories/bill_repository.dart';
import '../datasources/local/bill_local_datasource.dart';
import '../datasources/remote/bill_remote_datasource.dart';

class BillRepositoryImpl implements BillRepository {
  final BillRemoteDataSource _remote;
  final BillLocalDataSource _local;
  final OcrService _ocrService;

  BillRepositoryImpl(this._remote, this._local, this._ocrService);

  @override
  Future<Either<Failure, List<BillEntity>>> getBills({
    int page = 1,
    int pageSize = 20,
    BillFilter? filter,
  }) async {
    try {
      final bills = await _remote.getBills(page: page, pageSize: pageSize, filter: filter);
      if (page == 1) await _local.cacheBills(bills);
      return Right(bills);
    } on ServerException catch (e) {
      // Fallback to cache
      if (page == 1) {
        try {
          final cached = await _local.getCachedBills();
          return Right(cached);
        } catch (_) {}
      }
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      final cached = await _local.getCachedBills();
      return Right(cached);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, BillEntity>> getBillById(String id) async {
    try {
      final bill = await _remote.getBillById(id);
      return Right(bill);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, BillEntity>> createBill(BillEntity bill) async {
    try {
      final created = await _remote.createBill(bill);
      return Right(created);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, BillEntity>> updateBill(BillEntity bill) async {
    try {
      final updated = await _remote.updateBill(bill);
      return Right(updated);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteBill(String id) async {
    try {
      await _remote.deleteBill(id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<BillEntity>>> searchBills(String query) async {
    try {
      final results = await _remote.searchBills(query);
      return Right(results);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, OcrExtractedData>> extractBillFromImage(String imagePath) async {
    try {
      final data = await _ocrService.extractFromImage(imagePath);
      return Right(data);
    } on OcrException catch (e) {
      return Left(OcrFailure(e.message));
    } catch (e) {
      return Left(OcrFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, OcrExtractedData>> extractBillFromPdf(String pdfPath) async {
    try {
      // For PDF, we'd extract text using a PDF parser
      // then run OCR on extracted text
      final data = await _ocrService.extractFromText('PDF content placeholder');
      return Right(data);
    } catch (e) {
      return Left(OcrFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> uploadAttachment(String filePath, String billId) async {
    try {
      final url = await _remote.uploadAttachment(filePath, billId);
      return Right(url);
    } on StorageException catch (e) {
      return Left(StorageFailure(e.message));
    } catch (e) {
      return Left(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAttachment(String attachmentUrl) async {
    try {
      await _remote.deleteAttachment(attachmentUrl);
      return const Right(null);
    } catch (e) {
      return Left(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getDashboardStats() async {
    try {
      final stats = await _remote.getDashboardStats();
      return Right(stats);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<BillEntity>>> getExpiringWarranties(int days) async {
    try {
      final bills = await _remote.getExpiringWarranties(days);
      return Right(bills);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> exportToCsv(List<BillEntity> bills, String filePath) async {
    try {
      final rows = <List<dynamic>>[
        ['Product Name', 'Category', 'Purchase Date', 'Bill Number', 'Warranty (months)',
         'Warranty End', 'Amount', 'Current Value', 'Serial Number', 'Store', 'Status'],
        ...bills.map((b) => [
          b.productName,
          b.category,
          AppDateUtils.format(b.purchaseDate),
          b.billNumber ?? '',
          b.warrantyMonths ?? '',
          b.warrantyEndDate != null ? AppDateUtils.format(b.warrantyEndDate!) : '',
          b.purchaseAmount,
          b.currentValue ?? '',
          b.serialNumber ?? '',
          b.storeName ?? '',
          b.warrantyStatus.name,
        ]),
      ];

      final csv = const ListToCsvConverter().convert(rows);
      await File(filePath).writeAsString(csv);
      return const Right(null);
    } catch (e) {
      return Left(StorageFailure('CSV export failed: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> exportToPdf(List<BillEntity> bills, String filePath) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) => [
            pw.Header(level: 0, child: pw.Text('BillBoy - Purchase Summary')),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              headers: ['Product', 'Category', 'Date', 'Amount', 'Warranty'],
              data: bills.map((b) => [
                b.productName,
                b.category,
                AppDateUtils.format(b.purchaseDate),
                CurrencyUtils.format(b.purchaseAmount),
                b.warrantyStatus.name,
              ]).toList(),
            ),
          ],
        ),
      );

      final bytes = await pdf.save();
      await File(filePath).writeAsBytes(bytes);
      return const Right(null);
    } catch (e) {
      return Left(StorageFailure('PDF export failed: $e'));
    }
  }
}
