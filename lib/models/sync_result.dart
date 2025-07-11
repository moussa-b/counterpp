class SyncResult {
  final bool isSuccess;
  final String stepName;
  final String message;
  final Map<String, dynamic>? data;
  final int? statusCode;

  SyncResult._({
    required this.isSuccess,
    required this.stepName,
    required this.message,
    this.data,
    this.statusCode,
  });

  factory SyncResult.success({
    required String stepName,
    required String message,
    Map<String, dynamic>? data,
  }) {
    return SyncResult._(
      isSuccess: true,
      stepName: stepName,
      message: message,
      data: data,
    );
  }

  factory SyncResult.error({
    required String stepName,
    required String errorMessage,
    int? statusCode,
  }) {
    return SyncResult._(
      isSuccess: false,
      stepName: stepName,
      message: errorMessage,
      statusCode: statusCode,
    );
  }

  @override
  String toString() {
    return 'SyncResult(stepName: $stepName, isSuccess: $isSuccess, message: $message)';
  }
}
