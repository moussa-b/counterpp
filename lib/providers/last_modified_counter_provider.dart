import 'dart:async';

import 'package:counter/models/counter.dart';
import 'package:counter/providers/counter_repository_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LastModifiedCounterNotifier extends AsyncNotifier<Counter?> {
  LastModifiedCounterNotifier() : super();
  int _folderId = 0;

  @override
  FutureOr<Counter?> build() {
    return null;
  }

  Future<void> setFolderId(int folderId) async {
    _folderId = folderId;
    if (_folderId > 0) {
      final Counter? counter = await ref
          .read(counterRepositoryProvider)
          .getLastModifiedCounter(_folderId);
      update((Counter? previousState) => counter);
    } else {
      update((Counter? previousState) => null);
    }
  }

  void refresh() async {
    if (_folderId > 0) {
      setFolderId(_folderId);
    }
  }
}

final lastModifiedCounterProvider =
    AsyncNotifierProvider<LastModifiedCounterNotifier, Counter?>(() {
      return LastModifiedCounterNotifier();
    });
