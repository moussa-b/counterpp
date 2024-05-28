class Statistics {
  int? counterId;
  int? dateTimeStamp;
  int? folderId;
  int? id;
  StatisticsType? type;
  int? value;

  Statistics(
      {this.id, this.counterId, this.folderId, this.dateTimeStamp, this.type, this.value});

  Statistics.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    counterId = json['counterId'];
    folderId = json['folderId'];
    dateTimeStamp = json['dateTimeStamp'];
    type = getStatisticsTypeFromString(json['type']);
    value = json['value'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['counterId'] = counterId;
    data['folderId'] = folderId;
    data['dateTimeStamp'] = dateTimeStamp;
    data['id'] = id;
    data['type'] = type.toString().split('.').last;
    data['value'] = value;
    return data;
  }
}

enum StatisticsType {
  DECREMENT,
  INCREMENT,
  RESET
}

StatisticsType? getStatisticsTypeFromString(String str) {
  return StatisticsType.values
      .firstWhere((e) => e.name == str);
}
