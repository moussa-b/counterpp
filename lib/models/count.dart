class Count {
  final int counterId;
  final int count;

  Count({required this.counterId, required this.count});

  factory Count.fromJson(Map<String, dynamic> json) {
    return Count(counterId: json['counterId'], count: json['count']);
  }

  Map<String, dynamic> toJson() {
    return {'counterId': counterId, 'count': count};
  }
}
