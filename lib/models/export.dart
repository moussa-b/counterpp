import 'package:counterpp/models/statistics.dart';

import 'counter.dart';
import 'folder.dart';

class Export {
  List<Counter>? counters;
  int? databaseVersion;
  List<Folder>? folders;
  List<Statistics>? statistics;
  int? versionCode;
  String? versionName;

  Export(
      {this.counters,
        this.databaseVersion,
        this.folders,
        this.statistics,
        this.versionCode,
        this.versionName});

  Export.fromJson(Map<String, dynamic> json) {
    if (json['counters'] != null) {
      counters = <Counter>[];
      json['counters'].forEach((v) {
        counters!.add(Counter.fromJson(v));
      });
    }
    databaseVersion = json['databaseVersion'];
    if (json['folders'] != null) {
      folders = <Folder>[];
      json['folders'].forEach((v) {
        folders!.add(Folder.fromJson(v));
      });
    }
    if (json['statistics'] != null) {
      statistics = <Statistics>[];
      json['statistics'].forEach((v) {
        statistics!.add(Statistics.fromJson(v));
      });
    }
    versionCode = json['versionCode'];
    versionName = json['versionName'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (counters != null) {
      data['counters'] = counters!.map((v) => v.toJson()).toList();
    }
    data['databaseVersion'] = databaseVersion;
    if (folders != null) {
      data['folders'] = folders!.map((v) => v.toJson()).toList();
    }
    if (statistics != null) {
      data['statistics'] = statistics!.map((v) => v.toJson()).toList();
    }
    data['versionCode'] = versionCode;
    data['versionName'] = versionName;
    return data;
  }
}
