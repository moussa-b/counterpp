class OperationStatus {
  final bool status;
  final String? message;

  OperationStatus({required this.status, this.message});

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
    };
  }

  factory OperationStatus.fromJson(Map<String, dynamic> json) {
    return OperationStatus(
      status: json['status'] as bool,
      message: json['message'] as String?,
    );
  }
}
