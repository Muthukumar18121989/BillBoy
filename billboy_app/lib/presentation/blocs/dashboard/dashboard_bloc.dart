import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/repositories/bill_repository.dart';

// Events
abstract class DashboardEvent extends Equatable {
  const DashboardEvent();
  @override
  List<Object?> get props => [];
}

class DashboardLoadEvent extends DashboardEvent {}

class DashboardRefreshEvent extends DashboardEvent {}

// States
abstract class DashboardState extends Equatable {
  const DashboardState();
  @override
  List<Object?> get props => [];
}

class DashboardInitialState extends DashboardState {}

class DashboardLoadingState extends DashboardState {}

class DashboardLoadedState extends DashboardState {
  final int totalProducts;
  final double totalSpend;
  final int activeWarranties;
  final int expiredWarranties;
  final int upcomingExpiries;
  final Map<String, double> categoryBreakdown;
  final Map<String, double> monthlySpending;
  final List<Map<String, dynamic>> expiringWarranties;

  const DashboardLoadedState({
    required this.totalProducts,
    required this.totalSpend,
    required this.activeWarranties,
    required this.expiredWarranties,
    required this.upcomingExpiries,
    required this.categoryBreakdown,
    required this.monthlySpending,
    required this.expiringWarranties,
  });

  @override
  List<Object?> get props => [totalProducts, totalSpend];
}

class DashboardErrorState extends DashboardState {
  final String message;
  const DashboardErrorState(this.message);

  @override
  List<Object?> get props => [message];
}

// Bloc
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final BillRepository _repository;

  DashboardBloc(this._repository) : super(DashboardInitialState()) {
    on<DashboardLoadEvent>(_onLoad);
    on<DashboardRefreshEvent>(_onRefresh);
  }

  Future<void> _onLoad(DashboardLoadEvent event, Emitter<DashboardState> emit) async {
    emit(DashboardLoadingState());
    await _loadStats(emit);
  }

  Future<void> _onRefresh(DashboardRefreshEvent event, Emitter<DashboardState> emit) async {
    await _loadStats(emit);
  }

  Future<void> _loadStats(Emitter<DashboardState> emit) async {
    final result = await _repository.getDashboardStats();
    result.fold(
      (failure) => emit(DashboardErrorState(failure.message)),
      (stats) => emit(DashboardLoadedState(
        totalProducts: stats['totalProducts'] as int? ?? 0,
        totalSpend: (stats['totalSpend'] as num?)?.toDouble() ?? 0.0,
        activeWarranties: stats['activeWarranties'] as int? ?? 0,
        expiredWarranties: stats['expiredWarranties'] as int? ?? 0,
        upcomingExpiries: stats['upcomingExpiries'] as int? ?? 0,
        categoryBreakdown: Map<String, double>.from(stats['categoryBreakdown'] ?? {}),
        monthlySpending: Map<String, double>.from(stats['monthlySpending'] ?? {}),
        expiringWarranties: List<Map<String, dynamic>>.from(stats['expiringWarranties'] ?? []),
      )),
    );
  }
}
