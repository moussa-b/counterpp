import 'dart:convert';

import 'package:counter/l10n/app_localizations.dart';
import 'package:counter/providers/counter_repository_provider.dart';
import 'package:counter/providers/settings_provider.dart';
import 'package:counter/utils/synchronization_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

class SynchronizationScreen extends ConsumerStatefulWidget {
  const SynchronizationScreen({super.key});

  @override
  ConsumerState<SynchronizationScreen> createState() => _SynchronizationScreenState();
}

class _SynchronizationScreenState extends ConsumerState<SynchronizationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final _userController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isTestSuccessful = false;
  bool _isTesting = false;
  String? _accessToken;
  String? _apiUrl;
  String? _mailApiKey;
  String? _mailApiDomain;
  String? _mailSupport;

  @override
  void dispose() {
    _urlController.dispose();
    _userController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isTesting = true;
      _isTestSuccessful = false;
    });

    final urlText = _urlController.text.trim();
    final email = _userController.text.trim();
    final password = _passwordController.text;

    final uri = Uri.parse('$urlText/auth/login');
    final headers = {"Content-Type": "application/json"};
    final body = jsonEncode({
      "email": email,
      "password": password,
    });

    try {

      final response = await http.post(uri, headers: headers, body: body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = jsonDecode(response.body);
        if (kDebugMode) {
          debugPrint(responseData['access_token']);
        }
        setState(() {
          _accessToken = responseData['access_token'];
          _apiUrl = urlText;
          _mailApiKey = responseData['mail_api_key'];
          _mailApiDomain = responseData['mail_api_domain'];
          _mailSupport = responseData['mail_support'];
          _isTestSuccessful = true;
          _isTesting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Center(
              child: Text(
                AppLocalizations.of(context)!.successfulMsgTestSynchronization,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception("Erreur: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(e.toString());
      }
      setState(() {
        _isTestSuccessful = false;
        _isTesting = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.errorWhenTestTheSynchronization),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _validate() async {
    if (_isTestSuccessful) {
      final settings = await ref.read(counterRepositoryProvider).getSettings();
      settings.synchronizationAccessToken = _accessToken;
      settings.synchronizationApiUrl = _apiUrl;
      settings.mailApiKey = _mailApiKey;
      settings.mailApiDomain = _mailApiDomain;
      settings.mailSupport = _mailSupport;
      SynchronizationService().setApiUrl(apiUrl: _apiUrl!, apiAccessToken: _accessToken!);
      await ref.read(settingsProvider.notifier).updateSettings(settings);
      var messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.successfulMsgSaveSynchronization)
        ),
      );
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.synchronizationConfiguration),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)!.synchronizationInfo,
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _urlController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.synchronizationUrl,
                    hintText: 'https://exemple.com/api',
                    prefixIcon: const Icon(Icons.link),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppLocalizations.of(context)!.enterUrl;
                    }
                    if (Uri.tryParse(value)?.hasAbsolutePath != true ||
                        Uri.tryParse(value)?.hasScheme != true) {
                      return AppLocalizations.of(context)!.errorMsgEnterUrl;
                    }
                    return null;
                  },
                  onChanged: (_) => setState(() => _isTestSuccessful = false),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _userController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.username,
                    hintText: AppLocalizations.of(context)!.usernameHint,
                    prefixIcon: const Icon(Icons.person),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppLocalizations.of(context)!.enterUsername;
                    }
                    return null;
                  },
                  onChanged: (_) => setState(() => _isTestSuccessful = false),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.password,
                    hintText: AppLocalizations.of(context)!.passwordHint,
                    prefixIcon: const Icon(Icons.lock),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppLocalizations.of(context)!.enterPassword;
                    }
                    return null;
                  },
                  onChanged: (_) => setState(() => _isTestSuccessful = false),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _isTesting ? null : _testConnection,
                  icon: _isTesting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.wifi_protected_setup),
                  label: Text(_isTesting ? AppLocalizations.of(context)!.testing : AppLocalizations.of(context)!.testConnection),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _isTestSuccessful ? _validate : null,
                  icon: const Icon(Icons.check),
                  label: Text(AppLocalizations.of(context)!.validate),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: _isTestSuccessful ? Colors.green : Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                ),
                if (_isTestSuccessful) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context)!.testSuccessfulMessage,
                            style: const TextStyle(color: Colors.green),
                            textAlign: TextAlign.center,
                            softWrap: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
