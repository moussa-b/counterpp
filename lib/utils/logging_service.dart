import 'dart:async';
import 'dart:io';

import 'package:counter/models/app_config.dart';
import 'package:counter/models/settings.dart';
import 'package:counter/utils/mail_service.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Header names whose values must never reach the log file. The log is shown
/// in the developer screen and can be read off the device, so a bearer token
/// written here is a token leaked.
const Set<String> _sensitiveHeaderNames = {
  'authorization',
  'proxy-authorization',
  'cookie',
  'set-cookie',
};

/// Replaces the value of every credential-bearing header with a placeholder,
/// keeping the header names so the log still shows what was sent.
Map<String, String> redactSensitiveHeaders(Map<String, String> headers) {
  return headers.map(
    (String name, String value) => MapEntry(
      name,
      _sensitiveHeaderNames.contains(name.toLowerCase())
          ? '***redacted***'
          : value,
    ),
  );
}

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
    Settings? settings,
    bool sendEmail = true,
  }) async {
    final timestamp = DateTime.now().toUtc().toIso8601String();
    final buffer = StringBuffer()
      ..writeln('[$timestamp] HTTP $method ${url.toString()}')
      ..writeln('Status: ${statusCode ?? 'N/A'}');

    if (requestHeaders != null && requestHeaders.isNotEmpty) {
      buffer.writeln(
        'Request headers: ${redactSensitiveHeaders(requestHeaders)}',
      );
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

    await _appendBuffer(buffer);

    // Send email if enabled and settings are provided
    if (sendEmail && settings != null) {
      final emailContent = StringBuffer()
        ..writeln('HTTP Request Failure')
        ..writeln('Method: $method')
        ..writeln('URL: ${url.toString()}')
        ..writeln('Status: ${statusCode ?? 'N/A'}');

      if (error != null) {
        emailContent.writeln('Error: $error');
      }

      if (requestBody != null && requestBody.isNotEmpty) {
        emailContent.writeln('Request body: $requestBody');
      }

      if (responseBody != null && responseBody.isNotEmpty) {
        emailContent.writeln('Response body: $responseBody');
      }

      emailContent.writeln('Timestamp: $timestamp');

      await _sendErrorEmailIfNeeded(
        settings: settings,
        subject: 'Counter++ - HTTP Request Error',
        content: emailContent.toString(),
      );
    }
  }

  Future<void> logMessage(
    String message, {
    Map<String, Object?>? details,
    Object? error,
    StackTrace? stackTrace,
    Settings? settings,
    bool sendEmail = true,
  }) async {
    if (kDebugMode) {
      debugPrint('[LoggingService] $message');
      if (details != null && details.isNotEmpty) {
        debugPrint('[LoggingService] Details: $details');
      }
      if (error != null) {
        debugPrint('[LoggingService] Error: $error');
      }
      if (stackTrace != null) {
        debugPrint('[LoggingService] Stack trace: $stackTrace');
      }
    }

    final timestamp = DateTime.now().toUtc().toIso8601String();
    final buffer = StringBuffer()..writeln('[$timestamp] $message');

    if (details != null && details.isNotEmpty) {
      buffer.writeln('Details:');
      details.forEach((key, value) {
        buffer.writeln('  $key: $value');
      });
    }

    if (error != null) {
      buffer.writeln('Error: $error');
    }

    if (stackTrace != null) {
      buffer.writeln('Stack trace: $stackTrace');
    }

    buffer.writeln('---');

    await _appendBuffer(buffer);

    // Send email if enabled, settings are provided, and there's an error
    if (sendEmail && settings != null && error != null) {
      final emailContent = StringBuffer()
        ..writeln('Message: $message')
        ..writeln('Error: $error');

      if (details != null && details.isNotEmpty) {
        emailContent.writeln('Details:');
        details.forEach((key, value) {
          emailContent.writeln('  $key: $value');
        });
      }

      if (stackTrace != null) {
        emailContent.writeln('Stack trace: $stackTrace');
      }

      emailContent.writeln('Timestamp: $timestamp');

      await _sendErrorEmailIfNeeded(
        settings: settings,
        subject: 'Counter++ - Error',
        content: emailContent.toString(),
      );
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

  Future<void> _appendBuffer(StringBuffer buffer) async {
    try {
      final file = await _ensureLogFile();
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

  Future<void> _sendErrorEmailIfNeeded({
    required Settings settings,
    required String subject,
    required String content,
  }) async {
    // Check if mail configuration is available
    if (settings.mailApiKey == null ||
        settings.mailApiKey!.isEmpty ||
        settings.mailApiDomain == null ||
        settings.mailApiDomain!.isEmpty ||
        settings.mailSupport == null ||
        settings.mailSupport!.isEmpty) {
      return;
    }

    try {
      if (kDebugMode) {
        debugPrint('Sending error email to developer');
      }

      await MailService.sendEmail(
        apiKey: settings.mailApiKey!,
        domain: settings.mailApiDomain!,
        from: 'Counter++ Error <postmaster@${settings.mailApiDomain!}>',
        to: [AppConfig.developerEmail, settings.mailSupport!],
        subject: subject,
        text: 'An error occurred:\n\n$content',
      );
    } catch (e) {
      // Silently fail - email sending is not critical
      if (kDebugMode) {
        debugPrint('Failed to send error email: $e');
      }
    }
  }
}
