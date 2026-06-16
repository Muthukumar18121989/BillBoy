import 'package:equatable/equatable.dart';
import '../../../domain/entities/bill_entity.dart';
import '../../../domain/repositories/bill_repository.dart';

abstract class BillEvent extends Equatable {
  const BillEvent();
  @override
  List<Object?> get props => [];
}

class BillLoadEvent extends BillEvent {
  final int page;
  final BillFilter? filter;
  const BillLoadEvent({this.page = 1, this.filter});

  @override
  List<Object?> get props => [page, filter];
}

class BillLoadMoreEvent extends BillEvent {
  final BillFilter? filter;
  const BillLoadMoreEvent({this.filter});
}

class BillCreateEvent extends BillEvent {
  final BillEntity bill;
  const BillCreateEvent(this.bill);

  @override
  List<Object?> get props => [bill];
}

class BillUpdateEvent extends BillEvent {
  final BillEntity bill;
  const BillUpdateEvent(this.bill);

  @override
  List<Object?> get props => [bill.id];
}

class BillDeleteEvent extends BillEvent {
  final String id;
  const BillDeleteEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class BillSearchEvent extends BillEvent {
  final String query;
  const BillSearchEvent(this.query);

  @override
  List<Object?> get props => [query];
}

class BillFilterEvent extends BillEvent {
  final BillFilter filter;
  const BillFilterEvent(this.filter);

  @override
  List<Object?> get props => [filter];
}

class BillExtractOcrEvent extends BillEvent {
  final String filePath;
  final bool isPdf;
  const BillExtractOcrEvent(this.filePath, {this.isPdf = false});

  @override
  List<Object?> get props => [filePath];
}

class BillUploadAttachmentEvent extends BillEvent {
  final String filePath;
  final String billId;
  const BillUploadAttachmentEvent(this.filePath, this.billId);

  @override
  List<Object?> get props => [filePath, billId];
}

class BillExportCsvEvent extends BillEvent {}

class BillExportPdfEvent extends BillEvent {}
