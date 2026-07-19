import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/entities/bill_entity.dart';
import '../../../domain/repositories/bill_repository.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/depreciation_calculator.dart';
import 'bill_event.dart';
import 'bill_state.dart';

class BillBloc extends Bloc<BillEvent, BillState> {
  final BillRepository _repository;
  static const _uuid = Uuid();

  BillBloc(this._repository) : super(BillInitialState()) {
    on<BillLoadEvent>(_onLoad);
    on<BillLoadMoreEvent>(_onLoadMore);
    on<BillCreateEvent>(_onCreate);
    on<BillUpdateEvent>(_onUpdate);
    on<BillDeleteEvent>(_onDelete);
    on<BillSearchEvent>(_onSearch);
    on<BillFilterEvent>(_onFilter);
    on<BillExtractOcrEvent>(_onExtractOcr);
    on<BillExportCsvEvent>(_onExportCsv);
    on<BillExportPdfEvent>(_onExportPdf);
  }

  Future<void> _onLoad(BillLoadEvent event, Emitter<BillState> emit) async {
    emit(BillLoadingState());
    final result = await _repository.getBills(
      page: event.page,
      pageSize: AppConstants.pageSize,
      filter: event.filter,
    );
    result.fold(
      (failure) => emit(BillErrorState(failure.message)),
      (bills) => emit(BillLoadedState(
        bills: bills,
        hasMore: bills.length == AppConstants.pageSize,
        currentPage: event.page,
        activeFilter: event.filter,
        totalCount: bills.length,
      )),
    );
  }

  Future<void> _onLoadMore(BillLoadMoreEvent event, Emitter<BillState> emit) async {
    final currentState = state;
    if (currentState is! BillLoadedState || !currentState.hasMore) return;

    final nextPage = currentState.currentPage + 1;
    final result = await _repository.getBills(
      page: nextPage,
      pageSize: AppConstants.pageSize,
      filter: event.filter ?? currentState.activeFilter,
    );
    result.fold(
      (failure) => emit(BillErrorState(failure.message)),
      (newBills) => emit(currentState.copyWith(
        bills: [...currentState.bills, ...newBills],
        hasMore: newBills.length == AppConstants.pageSize,
        currentPage: nextPage,
        totalCount: currentState.totalCount + newBills.length,
      )),
    );
  }

  Future<void> _onCreate(BillCreateEvent event, Emitter<BillState> emit) async {
    final now = DateTime.now();
    final currentValue = DepreciationCalculator.calculateCurrentValue(
      purchaseAmount: event.bill.purchaseAmount,
      category: event.bill.category,
      purchaseDate: event.bill.purchaseDate,
    );

    final warrantyEnd = event.bill.warrantyMonths != null
        ? DateTime(
            event.bill.purchaseDate.year,
            event.bill.purchaseDate.month + event.bill.warrantyMonths!,
            event.bill.purchaseDate.day,
          )
        : null;

    final warrantyStatus = _computeWarrantyStatus(warrantyEnd);

    final billToCreate = BillEntity(
      id: event.bill.id.isEmpty ? _uuid.v4() : event.bill.id,
      userId: event.bill.userId,
      productName: event.bill.productName,
      category: event.bill.category,
      purchaseDate: event.bill.purchaseDate,
      billNumber: event.bill.billNumber,
      warrantyMonths: event.bill.warrantyMonths,
      warrantyEndDate: warrantyEnd,
      purchaseAmount: event.bill.purchaseAmount,
      taxAmount: event.bill.taxAmount,
      currentValue: currentValue,
      serialNumber: event.bill.serialNumber,
      imeiNumber: event.bill.imeiNumber,
      modelNumber: event.bill.modelNumber,
      brandName: event.bill.brandName,
      gstNumber: event.bill.gstNumber,
      storeName: event.bill.storeName,
      storeAddress: event.bill.storeAddress,
      attachmentUrls: event.bill.attachmentUrls,
      thumbnailUrl: event.bill.thumbnailUrl,
      ocrText: event.bill.ocrText,
      notes: event.bill.notes,
      warrantyStatus: warrantyStatus,
      createdAt: now,
      updatedAt: now,
    );

    final result = await _repository.createBill(billToCreate);
    result.fold(
      (failure) => emit(BillErrorState(failure.message)),
      (bill) {
        emit(BillCreatedState(bill));
        add(const BillLoadEvent());
      },
    );
  }

  Future<void> _onUpdate(BillUpdateEvent event, Emitter<BillState> emit) async {
    final warrantyEnd = event.bill.warrantyMonths != null
        ? DateTime(
            event.bill.purchaseDate.year,
            event.bill.purchaseDate.month + event.bill.warrantyMonths!,
            event.bill.purchaseDate.day,
          )
        : null;

    final currentValue = DepreciationCalculator.calculateCurrentValue(
      purchaseAmount: event.bill.purchaseAmount,
      category: event.bill.category,
      purchaseDate: event.bill.purchaseDate,
    );

    final updated = BillEntity(
      id: event.bill.id,
      userId: event.bill.userId,
      productName: event.bill.productName,
      category: event.bill.category,
      purchaseDate: event.bill.purchaseDate,
      billNumber: event.bill.billNumber,
      warrantyMonths: event.bill.warrantyMonths,
      warrantyEndDate: warrantyEnd,
      purchaseAmount: event.bill.purchaseAmount,
      taxAmount: event.bill.taxAmount,
      currentValue: currentValue,
      serialNumber: event.bill.serialNumber,
      imeiNumber: event.bill.imeiNumber,
      modelNumber: event.bill.modelNumber,
      brandName: event.bill.brandName,
      gstNumber: event.bill.gstNumber,
      storeName: event.bill.storeName,
      storeAddress: event.bill.storeAddress,
      attachmentUrls: event.bill.attachmentUrls,
      thumbnailUrl: event.bill.thumbnailUrl,
      ocrText: event.bill.ocrText,
      notes: event.bill.notes,
      warrantyStatus: _computeWarrantyStatus(warrantyEnd),
      createdAt: event.bill.createdAt,
      updatedAt: DateTime.now(),
    );

    final result = await _repository.updateBill(updated);
    result.fold(
      (failure) => emit(BillErrorState(failure.message)),
      (bill) => emit(BillUpdatedState(bill)),
    );
  }

  Future<void> _onDelete(BillDeleteEvent event, Emitter<BillState> emit) async {
    final result = await _repository.deleteBill(event.id);
    result.fold(
      (failure) => emit(BillErrorState(failure.message)),
      (_) {
        emit(BillDeletedState(event.id));
        add(const BillLoadEvent());
      },
    );
  }

  Future<void> _onSearch(BillSearchEvent event, Emitter<BillState> emit) async {
    if (event.query.isEmpty) {
      add(const BillLoadEvent());
      return;
    }
    final result = await _repository.searchBills(event.query);
    result.fold(
      (failure) => emit(BillErrorState(failure.message)),
      (results) => emit(BillSearchResultState(results: results, query: event.query)),
    );
  }

  Future<void> _onFilter(BillFilterEvent event, Emitter<BillState> emit) async {
    add(BillLoadEvent(filter: event.filter));
  }

  Future<void> _onExtractOcr(BillExtractOcrEvent event, Emitter<BillState> emit) async {
    emit(BillOcrProcessingState());
    final result = event.isPdf
        ? await _repository.extractBillFromPdf(event.filePath)
        : await _repository.extractBillFromImage(event.filePath);
    result.fold(
      (failure) => emit(BillErrorState(failure.message)),
      (data) => emit(BillOcrExtractedState(data)),
    );
  }

  Future<void> _onExportCsv(BillExportCsvEvent event, Emitter<BillState> emit) async {
    final currentState = state;
    if (currentState is! BillLoadedState) return;

    final dir = await getApplicationDocumentsDirectory();
    final filePath = '${dir.path}/billboy_export_${DateTime.now().millisecondsSinceEpoch}.csv';
    final result = await _repository.exportToCsv(currentState.bills, filePath);
    result.fold(
      (failure) => emit(BillErrorState(failure.message)),
      (_) => emit(BillExportSuccessState(filePath)),
    );
  }

  Future<void> _onExportPdf(BillExportPdfEvent event, Emitter<BillState> emit) async {
    final currentState = state;
    if (currentState is! BillLoadedState) return;

    final dir = await getApplicationDocumentsDirectory();
    final filePath = '${dir.path}/billboy_export_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final result = await _repository.exportToPdf(currentState.bills, filePath);
    result.fold(
      (failure) => emit(BillErrorState(failure.message)),
      (_) => emit(BillExportSuccessState(filePath)),
    );
  }

  WarrantyStatus _computeWarrantyStatus(DateTime? warrantyEnd) {
    if (warrantyEnd == null) return WarrantyStatus.noWarranty;
    final now = DateTime.now();
    if (now.isAfter(warrantyEnd)) return WarrantyStatus.expired;
    if (warrantyEnd.difference(now).inDays <= 30) return WarrantyStatus.expiringSoon;
    return WarrantyStatus.active;
  }
}
