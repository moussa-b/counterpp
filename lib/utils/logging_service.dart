import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Centralized logging utility to persist diagnostic information.
class LoggingService {
  LoggingService._internal();

  static final LoggingService _instance = LoggingService._internal();

  factory LoggingService() => _instance;

  File? _logFile;

  Future<File> _ensureLogFile() async {
    if (_logFile != null) {
      return _logFile!;
    }

    // Prevent concurrent initialization race conditions.
    return await Future.sync(() async {
      // Double-check locking in case another async call already initialized it.
      if (_logFile != null) {
        return _logFile!;
      }

      Directory directory;
      try {
        directory = await getApplicationDocumentsDirectory();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Failed to acquire application documents directory: $e');
        }
        rethrow;
      }

      final file = File('${directory.path}/counter_logs.txt');
      if (!await file.exists()) {
        await file.create(recursive: true);
      }

      _logFile = file;
      return file;
    });
  }

  Future<void> logHttpFailure({
    required String method,
    required Uri url,
    int? statusCode,
    Map<String, String>? requestHeaders,
    String? requestBody,
    String? responseBody,
    Object? error,
  }) async {
    try {
      final file = await _ensureLogFile();
      final timestamp = DateTime.now().toUtc().toIso8601String();
      final buffer = StringBuffer()
        ..writeln('[$timestamp] HTTP $method ${url.toString()}')
        ..writeln('Status: ${statusCode ?? 'N/A'}');

      if (requestHeaders != null && requestHeaders.isNotEmpty) {
        buffer.writeln('Request headers: $requestHeaders');
      }

      if (requestBody != null && requestBody.isNotEmpty) {
        buffer.writeln('Request body: $requestBody');
      }

      if (responseBody != null && responseBody.isNotEmpty) {
        buffer.writeln('Response body: $responseBody');
      }

      if (error != null) {
        buffer.writeln('Error: $error');
      }

      buffer.writeln('---');

      await file.writeAsString(
        buffer.toString(),
        mode: FileMode.append,
        flush: true,
      );
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('Failed to write log entry: $e');
        debugPrint('$stackTrace');
      }
    }
  }

  Future<String> readLogs() async {
    try {
      final file = await _ensureLogFile();
      if (await file.exists()) {
        return await file.readAsString();
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('Failed to read log file: $e');
        debugPrint('$stackTrace');
      }
    }
    return '';
  }

  Future<void> clearLogs() async {
    try {
      final file = await _ensureLogFile();
      await file.writeAsString('');
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('Failed to clear log file: $e');
        debugPrint('$stackTrace');
      }
    }
  }
}
