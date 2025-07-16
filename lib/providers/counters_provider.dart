import 'dart:async';

import 'package:counter/models/counter.dart';
import 'package:counter/models/reorder_item.dart';
import 'package:counter/models/settings.dart';
import 'package:counter/providers/counter_repository_provider.dart';
import 'package:counter/providers/folders_provider.dart';
import 'package:counter/repository/counter_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CountersNotifier extends AsyncNotifier<List<Counter>> {
  CountersNotifier() : super();
  int _folderId = 0;

  @override
  FutureOr<List<Counter>> build() {
    return [];
  }

  Future<void> setFolderId(int folderId) async {
    _folderId = folderId;
    if (_folderId > 0) {
      final CounterRepository counterRepository = ref.read(counterRepositoryProvider);
      final Settings settings = await ref.read(counterRepositoryProvider).getSettings();
      List<Counter> counters = await counterRepository.getCountersByFolderIdSorted(folderId, settings.counterSorting);
      update((List<Counter> previousState) => counters);
    } else {
      update((List<Counter> previousState) => []);
    }
  }

  Future<Counter?> updateCounter(Counter counter) async {
    final CounterRepository counterRepository = ref.read(counterRepositoryProvider);
    final Counter updatedCounter = await counterRepository.updateCounter(counter);
    if (updatedCounter.id != null && updatedCounter.id! > 0) {
      if (updatedCounter.folder != null && updatedCounter.folder!.id != null && updatedCounter.folder!.id! > 0) {
        ref.read(foldersProvider.notifier).refresh();
        if (updatedCounter.folder!.id == _folderId) {
          update((List<Counter> previousState) {
            final List<Counter> newState = [...previousState];
            final index = newState.indexWhere((Counter counter) => counter.id != null && counter.id == updatedCounter.id);
            newState[index] = updatedCounter;
            return newState;
          });
        }
      }
      return updatedCounter;
    }
    return null;
  }

  Future<Counter?> addCounter(Counter counter) async {
    final CounterRepository counterRepository = ref.read(counterRepositoryProvider);
    final Counter createdCounter = await counterRepository.createCounter(counter);
    if (createdCounter.id != null && createdCounter.id! > 0) {
      if (createdCounter.folder != null && createdCounter.folder!.id != null && createdCounter.folder!.id! > 0) {
        ref.read(foldersProvider.notifier).refresh();
        if (createdCounter.folder!.id == _folderId) {
          update((List<Counter> previousState) => [...previousState, createdCounter]);
        }
      }
      return createdCounter;
    }
    return null;
  }

  Future<bool> deleteCounter(Counter counterToDelete) async {
    final CounterRepository counterRepository = ref.read(counterRepositoryProvider);
    final bool deleted = await counterRepository.deleteCounterById(counterToDelete.id!);
    if (deleted) {
      update((List<Counter> previousState) => previousState.where((Counter counter) => counter.id != counterToDelete.id).toList());
      ref.read(foldersProvider.notifier).refresh();
      return deleted;
    }
    return false;
  }

  Future<Counter?> duplicateCounterById(int counterId, {String? suffix, bool resetValue = true}) async {
    final CounterRepository counterRepository = ref.read(counterRepositoryProvider);
    final Counter counter = await counterRepository.getCounterById(counterId);
    if (counter.id != null && counter.id! > 0) {
      counter.id = 0;
      if (suffix != null && suffix.isNotEmpty) {
        counter.name = '${counter.name}$suffix';
      }
      if (resetValue) {
        counter.counterCount = 0;
      }
      return addCounter(counter);
    }
    return null;
  }

  Future<bool> resetCounterById(int counterId) async {
    final CounterRepository counterRepository = ref.read(counterRepositoryProvider);
    final bool result = await counterRepository.resetCounterById(counterId);
    if (result) {
      update((List<Counter> previousState) {
        final List<Counter> newState = [...previousState];
        final index = newState.indexWhere((Counter counter) => counter.id != null && counter.id == counterId);
        newState[index].counterCount = 0;
        return newState;
      });
    }
    return result;
  }

  void refresh() async {
    if (_folderId > 0) {
      setFolderId(_folderId);
    }
  }

  Future<bool> onReorder(int oldIndex, int newIndex) async {
    final List<Counter> newState = [...state.value!];
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final Counter oldIndexCounter = newState.removeAt(oldIndex);
    newState.insert(newIndex, oldIndexCounter);
    update((List<Counter> previousState) => newState);
    final List<ReorderItem> reorderItems = newState.indexed.map((e) {
      final Counter counter = e.$2;
      final int index = e.$1;
      return ReorderItem(id: counter.id!, order: index);
    }).toList();
    final CounterRepository counterRepository = ref.read(counterRepositoryProvider);
    final bool result = await counterRepository.reorderCounters(reorderItems);
    return result;
  }
}

final countersProvider = AsyncNotifierProvider<CountersNotifier, List<Counter>>(() {
  return CountersNotifier();
});
