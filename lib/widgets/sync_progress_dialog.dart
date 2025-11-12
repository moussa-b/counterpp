import 'dart:async';
import 'dart:convert';

import 'package:counter/l10n/app_localizations.dart';
import 'package:counter/models/app_config.dart';
import 'package:counter/models/counter.dart';
import 'package:counter/models/folder.dart';
import 'package:counter/models/settings.dart';
import 'package:counter/models/sync_result.dart';
import 'package:counter/providers/counter_repository_provider.dart';
import 'package:counter/utils/mail_service.dart';
import 'package:counter/utils/logging_service.dart';
import 'package:counter/utils/synchronization_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart';

enum SyncStep {
  folders,
  deletedFolders,
  counters,
  deletedCounters,
}

class SyncProgressDialog extends ConsumerStatefulWidget {
  const SyncProgressDialog({super.key});

  @override
  ConsumerState<SyncProgressDialog> createState() => _SyncProgressDialogState();
}

class _SyncProgressDialogState extends ConsumerState<SyncProgressDialog>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final ScrollController _scrollController = ScrollController();

  SyncStep? _currentStep;
  bool _isCompleted = false;
  bool _hasError = false;
  String? _errorMessage;

  List<SyncStepData> _steps = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startSynchronization();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<SyncResult> Function() _convertToSyncResultFunction<T>(
    Future<Response?> Function(T param) function,
    T param,
    String stepName, {
    required SyncLabels labels,
    void Function(dynamic error)? onError,
  }) {
    return () async {
      try {
        final response = await function(param);
        if (response != null && response.statusCode >= 200 && response.statusCode < 300) {
          Map<String, dynamic>? responseData;
          try {
            responseData = json.decode(response.body);
          } catch (e) {
            // ignored
          }
          return responseData != null && responseData['status'] == true ? SyncResult.success(
            stepName: stepName,
            data: responseData,
            message: labels.syncSuccess,
          ) : SyncResult.error(
            stepName: stepName,
            errorMessage: labels.syncError,
            statusCode: response.statusCode,
          );
        } else {
          String errorMessage = '${labels.httpError} ${response != null ? response.statusCode : ''}';
          try {
            final errorData = json.decode(response != null ? response.body : '');
            if (errorData['message'] != null) {
              errorMessage = errorData['message'];
            }
          } catch (e) {
            // ignored
          }
          return SyncResult.error(
            stepName: stepName,
            errorMessage: errorMessage,
            statusCode: response?.statusCode,
          );
        }
      } catch (e) {
        onError?.call(e);
        String errorMessage = labels.connectionError;
        if (e.toString().contains('timeout')) {
          errorMessage = labels.timeoutError;
        } else if (e.toString().contains('SocketException')) {
          errorMessage = labels.synchronizationServerNotReachable;
        }
        return SyncResult.error(
          stepName: stepName,
          errorMessage: errorMessage,
        );
      }
    };
  }

  Future<void> _startSynchronization() async {
    final labels = SyncLabels(
      syncSuccess: AppLocalizations.of(context)!.syncSuccess,
      syncError: AppLocalizations.of(context)!.syncErrorTitle,
      httpError: AppLocalizations.of(context)!.httpError,
      connectionError: AppLocalizations.of(context)!.connectionError,
      timeoutError: AppLocalizations.of(context)!.timeoutError,
      synchronizationServerNotReachable: AppLocalizations.of(context)!.synchronizationServerNotReachable,
    );
    final List<Folder> folders = await ref.read(counterRepositoryProvider).getAllFoldersToSynchronize();
    final List<Counter> counters = await ref.read(counterRepositoryProvider).getAllCountersToSynchronize();
    final List<int> folderIds = await ref.read(counterRepositoryProvider).getAllDeletedFolderIdsToSynchronize();
    final List<int> counterIds = await ref.read(counterRepositoryProvider).getAllDeletedCounterIdsToSynchronize();
    final Settings settings = await ref.read(counterRepositoryProvider).getSettings();
    
    errorHandler(error) {
      unawaited(LoggingService().logMessage(
        'Synchronization error captured in SyncProgressDialog',
        details: {
          'step': _currentStep?.toString(),
          'hasMailConfig': settings.mailApiKey?.isNotEmpty == true &&
              settings.mailApiDomain?.isNotEmpty == true &&
              settings.mailSupport?.isNotEmpty == true,
        },
        error: error,
      ));
      if (kDebugMode) {
        debugPrint('Catch error: $error');
      }
      if (settings.mailApiKey != null && settings.mailApiKey!.isNotEmpty &&
          settings.mailApiDomain != null && settings.mailApiDomain!.isNotEmpty &&
          settings.mailSupport != null && settings.mailSupport!.isNotEmpty) {
        if (kDebugMode) {
          debugPrint('Sending error email to developer');
        }
        
        MailService.sendEmail(
          apiKey: settings.mailApiKey!,
          domain: settings.mailApiDomain!,
          from: 'Counter++ Error <postmaster@${settings.mailApiDomain!}>',
          to: [AppConfig.developerEmail, settings.mailSupport!],
          subject: 'Counter++ - Synchronization Error',
          text: 'An error occurred during synchronization:\n\nError: $error\n\nTimestamp: ${DateTime.now()}',
        );
      }
    }
    
    final List<Future<SyncResult> Function()> syncFunctions = [
      _convertToSyncResultFunction(SynchronizationService().synchronizeFolders, folders, _steps[0].title, labels: labels, onError: errorHandler),
      _convertToSyncResultFunction(SynchronizationService().synchronizeDeletedFolders, folderIds, _steps[1].title, labels: labels, onError: errorHandler),
      _convertToSyncResultFunction(SynchronizationService().synchronizeCounters, counters, _steps[2].title, labels: labels, onError: errorHandler),
      _convertToSyncResultFunction(SynchronizationService().synchronizeDeletedCounters, counterIds, _steps[3].title, labels: labels, onError: errorHandler),
    ];

    try {
      for (int i = 0; i < _steps.length; i++) {
        setState(() {
          _currentStep = _steps[i].step;
        });

        final result = await syncFunctions[i]();
        
        if (!result.isSuccess) {
          throw Exception(result.message);
        }
        
        await Future.delayed(const Duration(milliseconds: 800));
      }

      setState(() {
        _isCompleted = true;
        _currentStep = null;
      });

      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e, stackTrace) {
      unawaited(LoggingService().logMessage(
        'Synchronization flow failed',
        details: {
          'step': _currentStep?.toString(),
          'stepTitle': _currentStep != null
              ? _steps.firstWhere(
                  (s) => s.step == _currentStep,
                  orElse: () => SyncStepData(step: _currentStep!, title: _currentStep.toString(), icon: Icons.error),
                ).title
              : null,
        }..removeWhere((key, value) => value == null),
        error: e,
        stackTrace: stackTrace,
      ));
      setState(() {
        _hasError = true;
        _errorMessage = e.toString().replaceFirst(RegExp(r'^[a-zA-Z]+:\s*'), '').trim(); // remove "Exception:"
      });
    }

    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    _steps = [
      SyncStepData(
        step: SyncStep.folders,
        title: AppLocalizations.of(context)!.syncFolders,
        icon: Icons.folder,
      ),
      SyncStepData(
        step: SyncStep.deletedFolders,
        title: AppLocalizations.of(context)!.syncDeletedFolders,
        icon: Icons.folder_delete,
      ),
      SyncStepData(
        step: SyncStep.counters,
        title: AppLocalizations.of(context)!.syncCounters,
        icon: Icons.analytics,
      ),
      SyncStepData(
        step: SyncStep.deletedCounters,
        title: AppLocalizations.of(context)!.syncDeletedCounters,
        icon: Icons.analytics_outlined,
      ),
    ];
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding : const EdgeInsets.symmetric(horizontal: 24.0),
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                _buildHeader(),
                const SizedBox(height: 16),
                _buildStepsList(),
                const SizedBox(height: 16),
                _buildFooter(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    if (_hasError) {
      return Column(
        children: [
          const Icon(
            Icons.error,
            color: Colors.red,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context)!.syncErrorTitle,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
            textAlign: TextAlign.center,
            softWrap: true,
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? AppLocalizations.of(context)!.syncErrorMessage,
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    if (_isCompleted) {
      return Column(
        children: [
          const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context)!.syncCompletedTitle,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
            textAlign: TextAlign.center,
            softWrap: true,
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.syncCompletedMessage,
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return Column(
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        Text(
          AppLocalizations.of(context)!.syncInProgressTitle,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          softWrap: true,
        ),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.of(context)!.syncInProgressMessage,
          style: const TextStyle(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStepsList() {
    return Column(
      children: _steps.map((stepData) {
        return _buildStepItem(stepData);
      }).toList(),
    );
  }

  Widget _buildStepItem(SyncStepData stepData) {
    final isCurrentStep = _currentStep == stepData.step;
    final isCompleted = _isCompleted || 
        (_currentStep != null && 
         _steps.indexOf(stepData) < _steps.indexWhere((s) => s.step == _currentStep));

    Widget leadingWidget;

    if (_hasError && isCurrentStep) {
      leadingWidget = const Icon(Icons.error, color: Colors.red);
    } else if (isCompleted) {
      leadingWidget = const Icon(Icons.check_circle, color: Colors.green);
    } else if (isCurrentStep) {
      leadingWidget = const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    } else {
      leadingWidget = Icon(stepData.icon, color: Colors.grey);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrentStep ? Colors.blue.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentStep ? Colors.blue.withValues(alpha: 0.3) : Colors.transparent,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          leadingWidget,
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              stepData.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isCurrentStep ? FontWeight.w600 : FontWeight.normal,
                color: isCurrentStep ? Colors.blue : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    if (_hasError) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.close),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _hasError = false;
                _errorMessage = null;
                _currentStep = null;
                _isCompleted = false;
              });
              _startSynchronization();
            },
            child: Text(AppLocalizations.of(context)!.tryAgain),
          ),
        ],
      );
    }

    if (_isCompleted) {
      return ElevatedButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(AppLocalizations.of(context)!.close),
      );
    }

    return TextButton(
      onPressed: () => Navigator.of(context).pop(),
      child: Text(AppLocalizations.of(context)!.cancel),
    );
  }
}

class SyncStepData {
  final SyncStep step;
  final String title;
  final IconData icon;

  SyncStepData({
    required this.step,
    required this.title,
    required this.icon,
  });
}

class SyncLabels {
  final String syncSuccess;
  final String syncError;
  final String httpError;
  final String connectionError;
  final String timeoutError;
  final String synchronizationServerNotReachable;

  SyncLabels({
    required this.syncSuccess,
    required this.syncError,
    required this.httpError,
    required this.connectionError,
    required this.timeoutError,
    required this.synchronizationServerNotReachable,
  });
}
