import 'dart:async';

import 'package:counter/models/folder.dart';
import 'package:counter/models/reorder_item.dart';
import 'package:counter/models/settings.dart';
import 'package:counter/providers/counter_repository_provider.dart';
import 'package:counter/repository/counter_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FoldersNotifier extends AsyncNotifier<List<Folder>> {
  FoldersNotifier() : super();

  @override
  FutureOr<List<Folder>> build() async {
    final Settings settings = await ref
        .read(counterRepositoryProvider)
        .getSettings();
    return ref
        .read(counterRepositoryProvider)
        .getAllFoldersSorted(settings.folderSorting); // initialize data
  }

  void refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final Settings settings = await ref
          .read(counterRepositoryProvider)
          .getSettings();
      return ref
          .read(counterRepositoryProvider)
          .getAllFoldersSorted(settings.folderSorting);
    });
  }

  Future<Folder?> addFolder(String folderName) async {
    final CounterRepository counterRepository = ref.read(
      counterRepositoryProvider,
    );
    final Folder createdFolder = await counterRepository.createFolder(
      folderName,
    );
    if (createdFolder.id != null && createdFolder.id! > 0) {
      update((List<Folder> previousState) => [...previousState, createdFolder]);
      return createdFolder;
    }
    return null;
  }

  Future<Folder?> renameFolder(int folderId, String folderName) async {
    final CounterRepository counterRepository = ref.read(
      counterRepositoryProvider,
    );
    final Folder updatedFolder = await counterRepository.renameFolder(
      folderId,
      folderName,
    );
    if (updatedFolder.id != null && updatedFolder.id! > 0) {
      update((List<Folder> previousState) {
        final List<Folder> newState = [...previousState];
        final index = newState.indexWhere(
          (Folder folder) => folder.id != null && folder.id == updatedFolder.id,
        );
        newState[index] = updatedFolder;
        return newState;
      });
      return updatedFolder;
    }
    return null;
  }

  Future<bool> deleteFolderById(int folderId) async {
    final CounterRepository counterRepository = ref.read(
      counterRepositoryProvider,
    );
    final bool deleted = await counterRepository.deleteFolderById(folderId);
    if (deleted) {
      update(
        (List<Folder> previousState) => previousState
            .where((Folder folder) => folder.id != folderId)
            .toList(),
      );
      return deleted;
    }
    return false;
  }

  Future<Folder?> duplicateFolderById(int folderId, {String? suffix}) async {
    final CounterRepository counterRepository = ref.read(
      counterRepositoryProvider,
    );
    final Folder folder = await counterRepository.getFolderById(folderId);
    if (folder.id != null && folder.id! > 0) {
      return addFolder('${folder.name!}${suffix ?? ''}');
    }
    return null;
  }

  Future<bool> resetAllCountersForFolderId(int folderId) async {
    final CounterRepository counterRepository = ref.read(
      counterRepositoryProvider,
    );
    return counterRepository.resetAllCountersForFolderId(folderId);
  }

  Future<bool> deleteAllCountersForFolderId(int folderId) async {
    final CounterRepository counterRepository = ref.read(
      counterRepositoryProvider,
    );
    bool result = await counterRepository.deleteAllCountersForFolderId(
      folderId,
    );
    if (result) {
      update((List<Folder> previousState) {
        final List<Folder> newState = [...previousState];
        final index = newState.indexWhere(
          (Folder folder) => folder.id != null && folder.id == folderId,
        );
        newState[index].counterNumber = 0;
        return newState;
      });
    }
    return result;
  }

  /// [newIndex] is the index the folder ends up at once it has been removed
  /// from [oldIndex], the way `onReorderItem` and `ReorderableGridView` report
  /// it.
  Future<bool> onReorder(int oldIndex, int newIndex) async {
    final List<Folder> newState = [...state.value!];
    final Folder oldIndexFolder = newState.removeAt(oldIndex);
    newState.insert(newIndex, oldIndexFolder);
    update((List<Folder> previousState) => newState);
    final List<ReorderItem> reorderItems = newState.indexed.map((e) {
      final Folder folder = e.$2;
      final int index = e.$1;
      return ReorderItem(id: folder.id!, order: index);
    }).toList();
    final CounterRepository counterRepository = ref.read(
      counterRepositoryProvider,
    );
    final bool result = await counterRepository.reorderFolders(reorderItems);
    return result;
  }
}

final foldersProvider = AsyncNotifierProvider<FoldersNotifier, List<Folder>>(
  () {
    return FoldersNotifier();
  },
);
