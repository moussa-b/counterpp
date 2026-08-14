import 'dart:convert';
import 'dart:io';

import 'package:counter/l10n/app_localizations.dart';
import 'package:counter/models/app_config.dart';
import 'package:counter/models/counter.dart';
import 'package:counter/models/folder.dart';
import 'package:counter/models/recover_data.dart';
import 'package:counter/models/settings.dart';
import 'package:counter/models/statistics.dart';
import 'package:counter/providers/counter_repository_provider.dart';
import 'package:counter/repository/counter_repository.dart';
import 'package:counter/providers/folders_provider.dart';
import 'package:counter/providers/settings_provider.dart';
import 'package:counter/screens/developer_logs_screen.dart';
import 'package:counter/screens/synchronization_screen.dart';
import 'package:counter/screens/tutorial_screen.dart';
import 'package:counter/utils/logging_service.dart';
import 'package:counter/utils/synchronization_service.dart';
import 'package:counter/widgets/sync_progress_dialog.dart';
import 'package:downloadsfolder/downloadsfolder.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  Settings settings = Settings();
  String? version;
  bool synchronisationEnabled = SynchronizationService().isInitialized;
  final InAppReview inAppReview = InAppReview.instance;
  Directory? _downloadsDirectory;
  int _versionTapCount = 0;
  DateTime? _firstVersionTap;
  bool _developerTileVisible = false;

  @override
  void initState() {
    super.initState();
    _getSettings();
    _getDownloadPath();
  }

  void _getSettings() async {
    final Settings settingsFromDb = await ref
        .read(counterRepositoryProvider)
        .getSettings();
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      settings = settingsFromDb;
      version = packageInfo.version;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: ListView(
          children: [
            _SettingsSection(
              title: AppLocalizations.of(context)!.controls,
              children: [
                CheckboxListTile(
                  title: Text(AppLocalizations.of(context)!.activateSounds),
                  subtitle: Text(
                    AppLocalizations.of(context)!.activateSoundsSummary,
                  ),
                  value: settings.activateSounds ?? false,
                  onChanged: (value) {
                    setState(() {
                      settings.activateSounds = value;
                      ref
                          .read(settingsProvider.notifier)
                          .updateSettings(settings);
                    });
                  },
                ),
                const Divider(),
                CheckboxListTile(
                  title: Text(AppLocalizations.of(context)!.activateVibrator),
                  subtitle: Text(
                    AppLocalizations.of(context)!.activateVibratorSummary,
                  ),
                  value: settings.activateVibrator ?? false,
                  onChanged: (value) {
                    setState(() {
                      settings.activateVibrator = value;
                      ref
                          .read(settingsProvider.notifier)
                          .updateSettings(settings);
                    });
                  },
                ),
              ],
            ),
            _SettingsSection(
              title: AppLocalizations.of(context)!.display,
              children: [
                CheckboxListTile(
                  title: Text(AppLocalizations.of(context)!.keepScreenOn),
                  subtitle: Text(
                    AppLocalizations.of(context)!.keepScreenOnSummary,
                  ),
                  value: settings.keepScreenOn ?? false,
                  onChanged: (value) {
                    setState(() {
                      settings.keepScreenOn = value;
                      ref
                          .read(settingsProvider.notifier)
                          .updateSettings(settings);
                    });
                  },
                ),
              ],
            ),
            _SettingsSection(
              title: AppLocalizations.of(context)!.advanced,
              children: [
                ListTile(
                  title: Text(AppLocalizations.of(context)!.deleteAllCounters),
                  subtitle: Text(
                    AppLocalizations.of(context)!.deleteAllCountersSummary,
                  ),
                  onTap: () => _resetData(context),
                ),
                if (_downloadsDirectory != null) ...[
                  const Divider(),
                  ListTile(
                    title: Text(AppLocalizations.of(context)!.exportData),
                    subtitle: Text(
                      AppLocalizations.of(context)!.exportDataSummary,
                    ),
                    onTap: () => _exportData(context),
                  ),
                ],
                const Divider(),
                ListTile(
                  title: Text(AppLocalizations.of(context)!.importData),
                  subtitle: Text(
                    AppLocalizations.of(context)!.importDataSummary,
                  ),
                  onTap: () => _importData(context),
                ),
                if (synchronisationEnabled) ...[
                  const Divider(),
                  ListTile(
                    title: Text(AppLocalizations.of(context)!.synchronizeData),
                    subtitle: Text(
                      AppLocalizations.of(context)!.synchronizeDataSummary,
                    ),
                    onTap: () async {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext context) {
                          return const SyncProgressDialog();
                        },
                      );
                    },
                  ),
                  const Divider(),
                  ListTile(
                    title: Text(AppLocalizations.of(context)!.recoverData),
                    subtitle: Text(
                      AppLocalizations.of(context)!.recoverDataSummary,
                    ),
                    onTap: () {
                      _recoverData(context);
                    },
                  ),
                  const Divider(),
                  ListTile(
                    title: Text(
                      AppLocalizations.of(context)!.disableSynchronization,
                    ),
                    subtitle: Text(
                      AppLocalizations.of(
                        context,
                      )!.disableSynchronizationSummary,
                    ),
                    onTap: () {
                      _disableSynchronization(context);
                    },
                  ),
                ],
                if (!synchronisationEnabled) ...[
                  const Divider(),
                  ListTile(
                    title: Text(
                      AppLocalizations.of(context)!.enableSynchronization,
                    ),
                    subtitle: Text(
                      AppLocalizations.of(
                        context,
                      )!.enableSynchronizationSummary,
                    ),
                    onTap: () async {
                      _openSynchronizationScreen(context);
                    },
                  ),
                ],
              ],
            ),
            _SettingsSection(
              title: AppLocalizations.of(context)!.about,
              children: [
                ListTile(
                  title: Text(AppLocalizations.of(context)!.aboutSummary),
                ),
                const Divider(),
                ListTile(
                  title: Text(AppLocalizations.of(context)!.version),
                  subtitle: Text(version != null ? version! : ''),
                  onTap: () => _handleVersionTap(context),
                ),
                if (_developerTileVisible) ...[
                  const Divider(),
                  ListTile(
                    title: Text(AppLocalizations.of(context)!.developerOptions),
                    subtitle: Text(
                      AppLocalizations.of(context)!.developerOptionsSummary,
                    ),
                    onTap: () => _openDeveloperLogs(context),
                  ),
                ],
                const Divider(),
                ListTile(
                  title: Text(AppLocalizations.of(context)!.tutorial),
                  subtitle: Text(AppLocalizations.of(context)!.tutorialSummary),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (ctx) {
                          return const TutorialScreen();
                        },
                      ),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  title: Text(AppLocalizations.of(context)!.share),
                  subtitle: Text(AppLocalizations.of(context)!.shareSummary),
                  onTap: () => _shareApplication(context),
                ),
                const Divider(),
                ListTile(
                  title: Text(AppLocalizations.of(context)!.rate),
                  subtitle: Text(AppLocalizations.of(context)!.rateSummary),
                  onTap: () => _rateApplication(context),
                ),
                const Divider(),
                ListTile(
                  title: Text(AppLocalizations.of(context)!.contactUs),
                  subtitle: Text(
                    AppLocalizations.of(context)!.contactUsSummary,
                  ),
                  onTap: () => _contactUs(context),
                ),
                if (AppConfig.hasPrivacyPolicy) ...[
                  const Divider(),
                  ListTile(
                    title: Text(AppLocalizations.of(context)!.privacyPolicy),
                    onTap: () => _openPrivacyPolicy(context),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _getDownloadPath() async {
    Directory downloadsFolderPath;
    try {
      downloadsFolderPath = await getDownloadDirectory();
      if (!mounted) {
        return;
      }
      setState(() {
        _downloadsDirectory = downloadsFolderPath;
      });
    } on PlatformException {
      if (!mounted) {
        return;
      }
    }
  }

  /// [confirmCallback] is awaited and its failures surface as a snackbar.
  /// Taking a `Future<void> Function()` rather than a plain closure is what
  /// makes that possible: a `void` callback would run detached and any
  /// exception inside it would vanish, leaving the user with a dialog that
  /// closed as if the work had succeeded.
  void _showDialog(
    BuildContext context,
    Widget title,
    Widget content,
    Future<void> Function()? confirmCallback, {
    bool showCancel = true,
    String? validateLabel,
  }) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: title,
          content: content,
          actions: [
            if (showCancel == true)
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                },
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
            TextButton(
              onPressed: () async {
                // Resolved before the pop: ctx is defunct once the dialog is
                // gone, so the messenger and the label have to be captured now.
                final ScaffoldMessengerState messenger = ScaffoldMessenger.of(
                  context,
                );
                final String genericError = AppLocalizations.of(
                  context,
                )!.errorMsgGeneric;
                Navigator.of(ctx).pop();
                if (confirmCallback == null) {
                  return;
                }
                try {
                  await confirmCallback();
                } catch (e, stackTrace) {
                  await LoggingService().logMessage(
                    'Confirmed dialog action failed',
                    error: e,
                    stackTrace: stackTrace,
                  );
                  messenger.showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.white),
                          const SizedBox(width: 10),
                          Flexible(child: Text(genericError)),
                        ],
                      ),
                    ),
                  );
                }
              },
              child: Text(
                validateLabel ?? AppLocalizations.of(context)!.validate,
              ),
            ),
          ],
        );
      },
    );
  }

  // Takes the context explicitly: `downloadsfolder` re-exports package:path,
  // whose top-level `context` collides with State.context in this library.
  void _showErrorSnackBar(BuildContext ctx, String message) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 10),
            Flexible(child: Text(message)),
          ],
        ),
      ),
    );
  }

  void _exportData(BuildContext ctx) async {
    if (_downloadsDirectory != null) {
      try {
        List<Folder> folders = await ref
            .read(counterRepositoryProvider)
            .getAllFolders();
        List<Counter> counters = await ref
            .read(counterRepositoryProvider)
            .getAllCounters();
        Settings settings = await ref
            .read(counterRepositoryProvider)
            .getSettings();
        List<Statistics> statistics = await ref
            .read(counterRepositoryProvider)
            .getAllStatistics();
        // The export lands in the shared Downloads folder and users attach it
        // to support mails, so the sync token and Mailgun credentials must not
        // travel with it. They stay in the local database and are re-applied
        // from the synchronization screen instead.
        Map<String, dynamic> json = {
          'settings': settings.toJsonWithoutCredentials(),
        };
        if (folders.isNotEmpty) {
          json['folders'] = folders;
        }
        if (counters.isNotEmpty) {
          json['counters'] = counters;
        }
        if (statistics.isNotEmpty) {
          json['statistics'] = statistics;
        }
        final filePath =
            '${_downloadsDirectory!.path}/export_counter_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.json';
        final File file = File(filePath);
        final String jsonString = jsonEncode(json);
        final File writtenFile = await file.writeAsString(jsonString);
        if (await writtenFile.exists() && ctx.mounted) {
          final SnackBar snackBar = SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    AppLocalizations.of(
                      ctx,
                    )!.successfulMsgExportData(writtenFile.path),
                  ),
                ),
              ],
            ),
          );
          ScaffoldMessenger.of(ctx).showSnackBar(snackBar);
        }
      } catch (e, stackTrace) {
        await LoggingService().logMessage(
          'Data export failed',
          details: {'targetDirectory': _downloadsDirectory?.path},
          error: e,
          stackTrace: stackTrace,
        );
        if (!ctx.mounted) {
          return;
        }
        final SnackBar snackBar = SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 10),
              Flexible(child: Text(AppLocalizations.of(ctx)!.errorMsgGeneric)),
            ],
          ),
        );
        ScaffoldMessenger.of(ctx).showSnackBar(snackBar);
      }
    } else {
      if (!ctx.mounted) {
        return;
      }
      final SnackBar snackBar = SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 10),
            Flexible(
              child: Text(AppLocalizations.of(ctx)!.notSupportedMsgExportData),
            ),
          ],
        ),
      );
      ScaffoldMessenger.of(ctx).showSnackBar(snackBar);
    }
  }

  void _importData(BuildContext ctx) async {
    // file_picker 11 made FilePicker static; the instance-based
    // FilePicker.platform accessor is gone.
    final FilePickerResult? result = await FilePicker.pickFiles();
    if (result != null) {
      final String? filePath = result.files.single.path;
      if (filePath == null) {
        await LoggingService().logMessage(
          'Data import failed: missing file path',
        );
        if (!ctx.mounted) {
          return;
        }
        _showDialog(
          ctx,
          Text(AppLocalizations.of(ctx)!.error),
          Text(AppLocalizations.of(ctx)!.errorMsgImportData),
          null,
          showCancel: false,
          validateLabel: AppLocalizations.of(ctx)!.ok,
        );
        return;
      }

      final File file = File(filePath);
      try {
        final contents = await file.readAsString();
        if (contents.isNotEmpty) {
          var data = json.decode(contents);
          if (data['settings'] != null ||
              data['folders'] != null ||
              data['counters'] != null) {
            if (data['settings'] != null) {
              Settings settings = Settings.fromJson(data['settings']);
              settings.showTutorial = false;
              // Exports no longer carry credentials, so an import must not
              // blank out the sync configuration already on this device.
              final Settings current = await ref
                  .read(counterRepositoryProvider)
                  .getSettings();
              settings.synchronizationAccessToken ??=
                  current.synchronizationAccessToken;
              settings.synchronizationApiUrl ??= current.synchronizationApiUrl;
              settings.mailApiKey ??= current.mailApiKey;
              settings.mailApiDomain ??= current.mailApiDomain;
              settings.mailSupport ??= current.mailSupport;
              await ref
                  .read(counterRepositoryProvider)
                  .updateSettings(settings);
            }
            if (data['folders'] != null) {
              await ref.read(counterRepositoryProvider).deleteAllFolders();
              await ref
                  .read(counterRepositoryProvider)
                  .batchInsertFolders(
                    List<Map<String, Object?>>.from(data['folders']),
                  );
            }
            if (data['counters'] != null) {
              await ref.read(counterRepositoryProvider).deleteAllCounters();
              await ref
                  .read(counterRepositoryProvider)
                  .batchInsertCounters(
                    List<Map<String, Object?>>.from(data['counters']),
                  );
            }
            if (data['statistics'] != null) {
              await ref.read(counterRepositoryProvider).deleteAllStatistics();
              await ref
                  .read(counterRepositoryProvider)
                  .batchInsertStatistics(
                    List<Map<String, Object?>>.from(data['statistics']),
                  );
            }
            ref.read(foldersProvider.notifier).refresh();
            if (!ctx.mounted) {
              return;
            }
            final SnackBar snackBar = SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: Colors.white),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      AppLocalizations.of(ctx)!.successfulMsgImportData,
                    ),
                  ),
                ],
              ),
            );
            ScaffoldMessenger.of(ctx).showSnackBar(snackBar);
            return;
          }
        } else {
          await LoggingService().logMessage(
            'Data import failed: empty file',
            details: {'filePath': filePath},
          );
        }
      } catch (e, stackTrace) {
        await LoggingService().logMessage(
          'Data import failed',
          details: {'filePath': filePath},
          error: e,
          stackTrace: stackTrace,
        );
        if (!ctx.mounted) {
          return;
        }
        _showDialog(
          ctx,
          Text(AppLocalizations.of(ctx)!.error),
          Text(AppLocalizations.of(ctx)!.errorMsgImportData),
          null,
          showCancel: false,
          validateLabel: AppLocalizations.of(ctx)!.ok,
        );
        return;
      }

      await LoggingService().logMessage(
        'Data import failed: invalid file content',
        details: {'filePath': filePath},
      );
      if (!ctx.mounted) {
        return;
      }
      _showDialog(
        ctx,
        Text(AppLocalizations.of(ctx)!.error),
        Text(AppLocalizations.of(ctx)!.errorMsgImportData),
        null,
        showCancel: false,
        validateLabel: AppLocalizations.of(ctx)!.ok,
      );
    }
  }

  void _resetData(BuildContext context) {
    _showDialog(
      context,
      Text(AppLocalizations.of(context)!.warning),
      Text(AppLocalizations.of(context)!.warningMsgDeleteAllCounters),
      () async {
        final bool result = await ref
            .read(counterRepositoryProvider)
            .deleteAllFolders();
        ref.read(foldersProvider.notifier).refresh();
        await ref.read(counterRepositoryProvider).deleteAllCounters();
        await ref.read(counterRepositoryProvider).deleteAllStatistics();
        await ref.read(counterRepositoryProvider).deleteAllFoldersHistory();
        await ref.read(counterRepositoryProvider).deleteAllCountersHistory();
        if (result) {
          if (!context.mounted) {
            return;
          }
          final SnackBar snackBar = SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    AppLocalizations.of(context)!.successfulMsgDeleteAllData,
                  ),
                ),
              ],
            ),
          );
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        }
      },
    );
  }

  void _shareApplication(BuildContext context) async {
    final result = await SharePlus.instance.share(
      ShareParams(
        uri: Uri.parse(AppConfig.shareUrl),
        subject: AppLocalizations.of(context)!.shareSummary,
      ),
    );
    if (!context.mounted) {
      return;
    }
    if (result.status == ShareResultStatus.success) {
      final SnackBar snackBar = SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 10),
            Flexible(
              child: Text(AppLocalizations.of(context)!.thankYouForSharing),
            ),
          ],
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  void _rateApplication(BuildContext context) async {
    if (await inAppReview.isAvailable()) {
      inAppReview.requestReview();
    } else {
      if (!context.mounted) {
        return;
      }
      final SnackBar snackBar = SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 10),
            Flexible(
              child: Text(AppLocalizations.of(context)!.errorWhenRatingTheApp),
            ),
          ],
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  void _contactUs(BuildContext context) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: AppConfig.developerEmail,
      query: _encodeQueryParameters(<String, String>{
        'subject': AppConfig.appName,
        'body': 'Hello',
      }),
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      if (!context.mounted) {
        return;
      }
      final SnackBar snackBar = SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 10),
            Flexible(
              child: Text(AppLocalizations.of(context)!.errorWhenSendingEmail),
            ),
          ],
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  void _openSynchronizationScreen(BuildContext context) async {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (ctx) {
              return const SynchronizationScreen();
            },
          ),
        )
        .then((result) {
          if (result != null && result == true) {
            if (synchronisationEnabled !=
                SynchronizationService().isInitialized) {
              setState(() {
                synchronisationEnabled = SynchronizationService().isInitialized;
              });
            }
          }
        });
  }

  String? _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map(
          (MapEntry<String, String> e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
        )
        .join('&');
  }

  void _disableSynchronization(BuildContext context) {
    _showDialog(
      context,
      Text(AppLocalizations.of(context)!.warning),
      Text(AppLocalizations.of(context)!.warningMsgDisableSynchronization),
      () async {
        SynchronizationService().resetApiUrl();
        settings.synchronizationAccessToken = null;
        settings.synchronizationApiUrl = null;
        // Awaited outside setState: setState must stay synchronous, and these
        // writes previously ran detached with their failures swallowed.
        await ref.read(settingsProvider.notifier).updateSettings(settings);
        final CounterRepository repository = ref.read(
          counterRepositoryProvider,
        );
        await repository.resetCountersSynchronizationTimeStamp();
        await repository.resetFoldersSynchronizationTimeStamp();
        if (!mounted) {
          return;
        }
        setState(() {
          synchronisationEnabled = false;
        });
      },
      showCancel: true,
      validateLabel: AppLocalizations.of(context)!.ok,
    );
  }

  void _recoverData(BuildContext ctx) {
    _showDialog(
      ctx,
      Text(AppLocalizations.of(ctx)!.warning),
      Text(AppLocalizations.of(ctx)!.warningMsgRecover),
      () async {
        final RecoverData? recoverData = await SynchronizationService()
            .recoverData();
        final List<Folder> folders = recoverData?.folders ?? const [];
        final List<Counter> counters = recoverData?.counters ?? const [];
        // Deleting folders cascades to their counters, so nothing is destroyed
        // until the payload is known to be able to replace it. A response with
        // folders but no counters used to wipe every counter with no restore.
        if (folders.isEmpty || counters.isEmpty) {
          if (!ctx.mounted) {
            return;
          }
          _showErrorSnackBar(ctx, AppLocalizations.of(ctx)!.errorMsgGeneric);
          return;
        }

        final CounterRepository repository = ref.read(
          counterRepositoryProvider,
        );
        await repository.deleteAllStatistics();
        await repository.deleteAllFolders();
        await repository.deleteAllFoldersHistory();
        await repository.deleteAllCounters();
        await repository.deleteAllCountersHistory();
        await repository.batchInsertFolders(
          folders.map((folder) => folder.toJson()).toList(),
        );
        await repository.batchInsertCounters(
          counters.map((counter) => counter.toJson()).toList(),
        );
        ref.read(foldersProvider.notifier).refresh();
        if (!ctx.mounted) {
          return;
        }
        final SnackBar snackBar = SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white),
              const SizedBox(width: 10),
              Flexible(
                child: Text(AppLocalizations.of(ctx)!.successfulMsgImportData),
              ),
            ],
          ),
        );
        ScaffoldMessenger.of(ctx).showSnackBar(snackBar);
      },
      showCancel: true,
      validateLabel: AppLocalizations.of(ctx)!.ok,
    );
  }

  void _handleVersionTap(BuildContext context) {
    if (_developerTileVisible) {
      return;
    }

    final now = DateTime.now();
    if (_firstVersionTap == null ||
        now.difference(_firstVersionTap!) > const Duration(seconds: 2)) {
      _firstVersionTap = now;
      _versionTapCount = 1;
      return;
    }

    _versionTapCount += 1;
    if (_versionTapCount >= 7) {
      setState(() {
        _developerTileVisible = true;
        _versionTapCount = 0;
        _firstVersionTap = null;
      });
      if (!mounted) {
        return;
      }
      final snackBar = SnackBar(
        content: Row(
          children: [
            const Icon(Icons.code, color: Colors.white),
            const SizedBox(width: 10),
            Flexible(
              child: Text(AppLocalizations.of(context)!.developerModeEnabled),
            ),
          ],
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> _openPrivacyPolicy(BuildContext context) async {
    final Uri uri = Uri.parse(AppConfig.privacyPolicyUrl);
    final bool launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (launched || !context.mounted) {
      return;
    }
    _showErrorSnackBar(context, AppLocalizations.of(context)!.errorMsgGeneric);
  }

  void _openDeveloperLogs(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const DeveloperLogsScreen()));
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            title,
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Column(children: children),
      ],
    );
  }
}
