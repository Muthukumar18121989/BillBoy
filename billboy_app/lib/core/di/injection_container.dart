import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../data/datasources/local/bill_local_datasource.dart';
import '../../data/datasources/remote/bill_remote_datasource.dart';
import '../../data/datasources/remote/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/bill_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/bill_repository.dart';
import '../../presentation/blocs/auth/auth_bloc.dart';
import '../../presentation/blocs/bill/bill_bloc.dart';
import '../../presentation/blocs/dashboard/dashboard_bloc.dart';
import '../../presentation/blocs/warranty/warranty_bloc.dart';
import '../network/dio_client.dart';
import '../services/notification_service.dart';
import '../services/ocr_service.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // External
  final prefs = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(prefs);

  sl.registerSingleton<FirebaseAuth>(FirebaseAuth.instance);
  sl.registerSingleton<FirebaseFirestore>(FirebaseFirestore.instance);
  sl.registerSingleton<FirebaseStorage>(FirebaseStorage.instance);

  // Network
  sl.registerSingleton<Dio>(DioClient.createDio(prefs));

  // Services
  sl.registerSingleton<NotificationService>(NotificationService());
  sl.registerSingleton<OcrService>(OcrService());

  await sl<NotificationService>().initialize();

  // Data Sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(sl<FirebaseAuth>(), sl<FirebaseFirestore>()),
  );

  sl.registerLazySingleton<BillRemoteDataSource>(
    () => BillRemoteDataSourceImpl(sl<FirebaseFirestore>(), sl<FirebaseStorage>()),
  );

  sl.registerLazySingleton<BillLocalDataSource>(
    () => BillLocalDataSourceImpl(sl<SharedPreferences>()),
  );

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl<AuthRemoteDataSource>()),
  );

  sl.registerLazySingleton<BillRepository>(
    () => BillRepositoryImpl(
      sl<BillRemoteDataSource>(),
      sl<BillLocalDataSource>(),
      sl<OcrService>(),
    ),
  );

  // BLoCs
  sl.registerFactory<AuthBloc>(() => AuthBloc(sl<AuthRepository>()));
  sl.registerFactory<BillBloc>(() => BillBloc(sl<BillRepository>()));
  sl.registerFactory<DashboardBloc>(() => DashboardBloc(sl<BillRepository>()));
  sl.registerFactory<WarrantyBloc>(() => WarrantyBloc(sl<BillRepository>()));
}
