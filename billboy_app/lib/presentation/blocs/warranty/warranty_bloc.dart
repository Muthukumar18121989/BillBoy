import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/bill_entity.dart';
import '../../../domain/repositories/bill_repository.dart';

// Events
abstract class WarrantyEvent extends Equatable {
  const WarrantyEvent();
  @override
  List<Object?> get props => [];
}

class WarrantyLoadExpiringEvent extends WarrantyEvent {
  final int days;
  const WarrantyLoadExpiringEvent({this.days = 90});
  @override
  List<Object?> get props => [days];
}

// States
abstract class WarrantyState extends Equatable {
  const WarrantyState();
  @override
  List<Object?> get props => [];
}

class WarrantyInitialState extends WarrantyState {}
class WarrantyLoadingState extends WarrantyState {}

class WarrantyLoadedState extends WarrantyState {
  final List<BillEntity> expiringBills;
  final int days;

  const WarrantyLoadedState({required this.expiringBills, required this.days});

  @override
  List<Object?> get props => [expiringBills, days];
}

class WarrantyErrorState extends WarrantyState {
  final String message;
  const WarrantyErrorState(this.message);
  @override
  List<Object?> get props => [message];
}

// Bloc
class WarrantyBloc extends Bloc<WarrantyEvent, WarrantyState> {
  final BillRepository _repository;

  WarrantyBloc(this._repository) : super(WarrantyInitialState()) {
    on<WarrantyLoadExpiringEvent>(_onLoadExpiring);
  }

  Future<void> _onLoadExpiring(WarrantyLoadExpiringEvent event, Emitter<WarrantyState> emit) async {
    emit(WarrantyLoadingState());
    final result = await _repository.getExpiringWarranties(event.days);
    result.fold(
      (failure) => emit(WarrantyErrorState(failure.message)),
      (bills) => emit(WarrantyLoadedState(expiringBills: bills, days: event.days)),
    );
  }
}
