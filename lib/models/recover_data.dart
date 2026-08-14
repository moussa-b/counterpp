import 'package:counter/models/counter.dart';
import 'package:counter/models/folder.dart';

class RecoverData {
  List<Folder>? folders;
  List<Counter>? counters;

  RecoverData({required this.folders, required this.counters});

  factory RecoverData.fromJson(Map<String, dynamic> json) {
    return RecoverData(
      folders: (json['folders'] as List)
          .map((item) => Folder.fromJson(item))
          .toList(),
      counters: (json['counters'] as List)
          .map((item) => Counter.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'folders': folders == null
          ? []
          : folders!.map((folder) => folder.toJson()).toList(),
      'counters': counters == null
          ? []
          : counters!.map((counter) => counter.toJson()).toList(),
    };
  }
}
