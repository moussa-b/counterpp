import 'dart:convert';

import 'package:counter/models/count.dart';
import 'package:counter/models/counter.dart';
import 'package:counter/models/folder.dart';
import 'package:counter/models/recover_data.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart' show Response;

import 'logging_service.dart';

class SynchronizationService {
  static final SynchronizationService _instance =
      SynchronizationService._internal();

  factory SynchronizationService() => _instance;

  SynchronizationService._internal();

  String? _apiUrl;
  String? _apiAccessToken;
  http.Client _client = http.Client();

  /// Swaps in a stub client so tests can drive every response path without a
  /// network. Production code never calls this.
  @visibleForTesting
  set client(http.Client client) => _client = client;

  bool get isInitialized {
    return _apiUrl != null &&
        isValidUrl(_apiUrl!) &&
        _apiAccessToken != null &&
        _apiAccessToken!.isNotEmpty;
  }

  Map<String, String> get autorizationHeaders => {
    'Authorization': 'Bearer $_apiAccessToken',
  };

  /// Returns false and keeps the previous configuration when the arguments are
  /// unusable, so callers can tell the user instead of silently syncing to the
  /// old endpoint.
  bool setApiUrl({required String apiUrl, required String apiAccessToken}) {
    if (isValidUrl(apiUrl) && apiAccessToken.isNotEmpty) {
      _apiUrl = apiUrl;
      _apiAccessToken = apiAccessToken;
      return true;
    }
    return false;
  }

  void resetApiUrl() {
    _apiAccessToken = null;
    _apiUrl = null;
  }

  static bool isValidUrl(String url) {
    final uri = Uri.tryParse(url);
    return uri != null && uri.hasScheme && uri.hasAuthority;
  }

  Future<http.Response?> post(
    String endpoint, {
    Map<String, String>? headers,
    Object? body,
    bool ignoreErrors = false,
  }) async {
    final url = Uri.parse(endpoint);
    final mergedHeaders = {...?headers, 'Content-Type': 'application/json'};
    final serializedBody = body == null
        ? null
        : body is String
        ? body
        : jsonEncode(body);

    try {
      final response = await _client.post(
        url,
        headers: mergedHeaders,
        body: serializedBody,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response;
      } else {
        await LoggingService().logHttpFailure(
          method: 'POST',
          url: url,
          statusCode: response.statusCode,
          requestHeaders: mergedHeaders,
          requestBody: serializedBody,
          responseBody: response.body,
        );
        if (!ignoreErrors) {
          throw Exception(
            'Error HTTP ${response.statusCode} : ${response.body}',
          );
        }
        if (kDebugMode) {
          debugPrint('Ignored error (code ${response.statusCode})');
        }
      }
    } catch (e) {
      await LoggingService().logHttpFailure(
        method: 'POST',
        url: url,
        requestHeaders: mergedHeaders,
        requestBody: serializedBody,
        error: e,
      );
      if (!ignoreErrors) rethrow;
      if (kDebugMode) {
        debugPrint('Ignored network error : $e');
      }
    }

    return null;
  }

  Future<http.Response?> delete(
    String endpoint, {
    Map<String, String>? headers,
    Object? body,
    bool ignoreErrors = false,
  }) async {
    final url = Uri.parse(endpoint);
    final mergedHeaders = {...?headers, 'Content-Type': 'application/json'};
    final serializedBody = body == null
        ? null
        : body is String
        ? body
        : jsonEncode(body);

    try {
      final response = await _client.delete(
        url,
        headers: mergedHeaders,
        body: serializedBody,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response;
      } else {
        await LoggingService().logHttpFailure(
          method: 'DELETE',
          url: url,
          statusCode: response.statusCode,
          requestHeaders: mergedHeaders,
          requestBody: serializedBody,
          responseBody: response.body,
        );
        if (!ignoreErrors) {
          throw Exception(
            'Error HTTP ${response.statusCode} : ${response.body}',
          );
        }
        if (kDebugMode) {
          debugPrint('Ignored error (code ${response.statusCode})');
        }
      }
    } catch (e) {
      await LoggingService().logHttpFailure(
        method: 'DELETE',
        url: url,
        requestHeaders: mergedHeaders,
        requestBody: serializedBody,
        error: e,
      );
      if (!ignoreErrors) rethrow;
      if (kDebugMode) {
        debugPrint('Ignored network error : $e');
      }
    }

    return null;
  }

  Future<http.Response?> get(
    String endpoint, {
    Map<String, String>? headers,
    bool ignoreErrors = false,
  }) async {
    final url = Uri.parse(endpoint);
    final mergedHeaders = {...?headers, 'Content-Type': 'application/json'};

    try {
      final response = await _client.get(url, headers: mergedHeaders);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response;
      } else {
        await LoggingService().logHttpFailure(
          method: 'GET',
          url: url,
          statusCode: response.statusCode,
          requestHeaders: mergedHeaders,
          responseBody: response.body,
        );
        if (!ignoreErrors) {
          throw Exception(
            'Error HTTP ${response.statusCode} : ${response.body}',
          );
        }
        if (kDebugMode) {
          debugPrint('Ignored error (code ${response.statusCode})');
        }
      }
    } catch (e) {
      await LoggingService().logHttpFailure(
        method: 'GET',
        url: url,
        requestHeaders: mergedHeaders,
        error: e,
      );
      if (!ignoreErrors) rethrow;
      if (kDebugMode) {
        debugPrint('Ignored network error : $e');
      }
    }

    return null;
  }

  void requestInBackground(
    Future<http.Response?> Function(
      String endpoint, {
      Map<String, String>? headers,
      Object? body,
      bool ignoreErrors,
    })
    requestFunction,
    String endpoint, {
    Map<String, String>? headers,
    Object? body,
  }) {
    Future.microtask(
      () => requestFunction(
        endpoint,
        headers: headers,
        body: body,
        ignoreErrors: true,
      ),
    );
  }

  Future<Response?> synchronizeFolders(List<Folder> folders) async {
    if (!isInitialized) {
      return null;
    }
    if (kDebugMode) {
      debugPrint('Synchronize folders : $_apiUrl/folders/synchronize');
    }
    return await post(
      '$_apiUrl/folders/synchronize',
      body: folders,
      headers: autorizationHeaders,
    );
  }

  Future<Response?> synchronizeCounters(List<Counter> counters) async {
    if (!isInitialized) {
      return null;
    }
    if (kDebugMode) {
      debugPrint('Synchronize counters : $_apiUrl/counters/synchronize');
    }
    return await post(
      '$_apiUrl/counters/synchronize',
      body: counters,
      headers: autorizationHeaders,
    );
  }

  Future<Response?> synchronizeDeletedFolders(List<int> folderIds) async {
    if (!isInitialized) {
      return null;
    }
    if (kDebugMode) {
      debugPrint('Synchronize deleted folders : $_apiUrl/folders/delete');
    }
    return await delete(
      '$_apiUrl/folders/delete',
      body: folderIds,
      headers: autorizationHeaders,
    );
  }

  Future<Response?> synchronizeDeletedCounters(List<int> counterIds) async {
    if (!isInitialized) {
      return null;
    }
    if (kDebugMode) {
      debugPrint('Synchronize deleted counters : $_apiUrl/counters/delete');
    }
    return await delete(
      '$_apiUrl/counters/delete',
      body: counterIds,
      headers: autorizationHeaders,
    );
  }

  Future<Response?> synchronizeCountersCount(List<Count> counts) async {
    if (!isInitialized) {
      return null;
    }
    if (kDebugMode) {
      debugPrint(
        'Synchronize counter counts : $_apiUrl/counters/count/synchronize',
      );
    }
    return await post(
      '$_apiUrl/counters/count/synchronize',
      body: counts,
      headers: autorizationHeaders,
    );
  }

  Future<RecoverData?> recoverData() async {
    if (!isInitialized) {
      return null;
    }
    if (kDebugMode) {
      debugPrint('Recover counter data : $_apiUrl/users/recover');
    }
    final response = await get(
      '$_apiUrl/users/recover',
      headers: autorizationHeaders,
    );
    if (response != null &&
        response.statusCode >= 200 &&
        response.statusCode < 300) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return RecoverData.fromJson(jsonData);
    }
    return null;
  }
}
