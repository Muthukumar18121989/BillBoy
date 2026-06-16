import 'package:equatable/equatable.dart';
import '../../../domain/entities/bill_entity.dart';
import '../../../domain/repositories/bill_repository.dart';

abstract class BillState extends Equatable {
  const BillState();
  @override
  List<Object?> get props => [];
}

class BillInitialState extends BillState {}

class BillLoadingState extends BillState {}

class BillLoadedState extends BillState {
  final List<BillEntity> bills;
  final bool hasMore;
  final int currentPage;
  final BillFilter? activeFilter;
  final int totalCount;

  const BillLoadedState({
    required this.bills,
    this.hasMore = false,
    this.currentPage = 1,
    this.activeFilter,
    this.totalCount = 0,
  });

  BillLoadedState copyWith({
    List<BillEntity>? bills,
    bool? hasMore,
    int? currentPage,
    BillFilter? activeFilter,
    int? totalCount,
  }) {
    return BillLoadedState(
      bills: bills ?? this.bills,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      activeFilter: activeFilter ?? this.activeFilter,
      totalCount: totalCount ?? this.totalCount,
    );
  }

  @override
  List<Object?> get props => [bills, hasMore, currentPage, totalCount];
}

class BillCreatedState extends BillState {
  final BillEntity bill;
  const BillCreatedState(this.bill);

  @override
  List<Object?> get props => [bill.id];
}

class BillUpdatedState extends BillState {
  final BillEntity bill;
  const BillUpdatedState(this.bill);

  @override
  List<Object?> get props => [bill.id];
}

class BillDeletedState extends BillState {
  final String id;
  const BillDeletedState(this.id);

  @override
  List<Object?> get props => [id];
}

class BillSearchResultState extends BillState {
  final List<BillEntity> results;
  final String query;

  const BillSearchResultState({required this.results, required this.query});

  @override
  List<Object?> get props => [query, results];
}

class BillOcrExtractedState extends BillState {
  final OcrExtractedData data;
  const BillOcrExtractedState(this.data);

  @override
  List<Object?> get props => [data];
}

class BillOcrProcessingState extends BillState {}

class BillExportSuccessState extends BillState {
  final String filePath;
  const BillExportSuccessState(this.filePath);

  @override
  List<Object?> get props => [filePath];
}

class BillErrorState extends BillState {
  final String message;
  const BillErrorState(this.message);

  @override
  List<Object?> get props => [message];
}
