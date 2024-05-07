import 'package:counterpp/repository/counter_repository.dart';
import 'package:counterpp/repository/database_counter_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final asyncCounterRepositoryProvider = FutureProvider<CounterRepository>((ref) async {
  final CounterRepository databaseCounterRepository = DatabaseCounterRepository();
  await databaseCounterRepository.initialize();
  return databaseCounterRepository;
});

final counterRepositoryProvider = Provider<CounterRepository>((ref) {
  final AsyncValue<CounterRepository> counterRepository = ref.watch(asyncCounterRepositoryProvider);
  return counterRepository.value!;
});
