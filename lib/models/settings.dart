import 'package:counter/models/sorting_options.dart';

class Settings {
  SortingOptions? folderSorting;
  SortingOptions? counterSorting;
  bool? counterCompactView;
  bool? activateSounds;
  bool? activateVibrator;
  bool? keepScreenOn;
  bool? showTutorial;
  int? lastModificationTimeStamp;
  String? synchronizationAccessToken;
  String? synchronizationApiUrl;

  Settings({this.folderSorting, this.counterSorting, this.counterCompactView = false, this.lastModificationTimeStamp});

  Settings.fromJson(Map<String, dynamic> json) {
    activateSounds = json['activateSounds'] == 1;
    activateVibrator = json['activateVibrator'] == 1;
    counterCompactView = json['counterCompactView'] == 1;
    counterSorting = json['counterSorting'] != null ? SortingOptions.values[json['counterSorting']] : null;
    folderSorting = json['folderSorting'] != null ? SortingOptions.values[json['folderSorting']] : null;
    keepScreenOn = json['keepScreenOn'] == 1;
    lastModificationTimeStamp = json['lastModificationTimeStamp'];
    synchronizationAccessToken = json['synchronizationAccessToken'];
    synchronizationApiUrl = json['synchronizationApiUrl'];
    showTutorial = json['showTutorial'] != null ? (json['showTutorial'] == 1) : true;
  }

  Settings.copy(Settings toCopy) {
    activateSounds = toCopy.activateSounds;
    activateVibrator = toCopy.activateVibrator;
    counterCompactView = toCopy.counterCompactView;
    counterSorting = toCopy.counterSorting;
    folderSorting = toCopy.folderSorting;
    keepScreenOn = toCopy.keepScreenOn;
    lastModificationTimeStamp = toCopy.lastModificationTimeStamp;
    synchronizationAccessToken = toCopy.synchronizationAccessToken;
    synchronizationApiUrl = toCopy.synchronizationApiUrl;
    showTutorial = toCopy.showTutorial;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['activateSounds'] = (activateSounds == true ? 1 : 0);
    data['activateVibrator'] = (activateVibrator == true ? 1 : 0);
    data['counterCompactView'] = (counterCompactView == true ? 1 : 0);
    data['counterSorting'] = counterSorting;
    data['folderSorting'] = folderSorting;
    data['keepScreenOn'] = (keepScreenOn == true ? 1 : 0);
    data['lastModificationTimeStamp'] = lastModificationTimeStamp;
    data['synchronizationAccessToken'] = synchronizationAccessToken;
    data['synchronizationApiUrl'] = synchronizationApiUrl;
    data['showTutorial'] = (showTutorial == true ? 1 : 0);
    return data;
  }
}
