import 'package:counterpp/models/sorting_options.dart';

class Settings {
  SortingOptions? folderSorting;
  SortingOptions? counterSorting;
  bool? counterCompactView;
  int? lastModificationTimeStamp;

  Settings({this.folderSorting, this.counterSorting, this.counterCompactView = false, this.lastModificationTimeStamp});

  Settings.fromJson(Map<String, dynamic> json) {
    counterCompactView = json['counterCompactView'] == 1;
    counterSorting = json['counterSorting'] != null ? SortingOptions.values[json['counterSorting']] : null;
    folderSorting = json['folderSorting'] != null ? SortingOptions.values[json['folderSorting']] : null;
    lastModificationTimeStamp = json['lastModificationTimeStamp'];
  }

  Settings.copy(Settings toCopy) {
    counterCompactView = toCopy.counterCompactView;
    counterSorting = toCopy.counterSorting;
    folderSorting = toCopy.folderSorting;
    lastModificationTimeStamp = toCopy.lastModificationTimeStamp;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['counterCompactView'] = (counterCompactView == true ? 1 : 0);
    data['counterSorting'] = counterSorting;
    data['folderSorting'] = folderSorting;
    data['lastModificationTimeStamp'] = lastModificationTimeStamp;
    return data;
  }
}
