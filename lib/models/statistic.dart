class Statistic {
  int? counterId;
  int? dateTimeStamp;
  int? id;
  StatisticType? type;
  int? value;

  Statistic(
      {this.counterId, this.dateTimeStamp, this.id, this.type, this.value});

  Statistic.fromJson(Map<String, dynamic> json) {
    counterId = json['counterId'];
    dateTimeStamp = json['dateTimeStamp'];
    id = json['id'];
    type = json['type'];
    value = json['value'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['counterId'] = counterId;
    data['dateTimeStamp'] = dateTimeStamp;
    data['id'] = id;
    data['type'] = type;
    data['value'] = value;
    return data;
  }
}

enum StatisticType {
  DECREMENT,
  INCREMENT,
  RESET
}
