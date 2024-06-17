import 'dart:convert';
import 'dart:io';

import 'package:counterpp/models/app_config.dart';
import 'package:counterpp/models/counter.dart';
import 'package:counterpp/models/folder.dart';
import 'package:counterpp/models/settings.dart';
import 'package:counterpp/models/statistics.dart';
import 'package:counterpp/providers/counter_repository_provider.dart';
import 'package:counterpp/providers/folders_provider.dart';
import 'package:counterpp/providers/settings_provider.dart';
import 'package:counterpp/utils/permission-utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
  final InAppReview inAppReview = InAppReview.instance;

  @override
  void initState() {
    super.initState();
    getSettings();
  }

  void getSettings() async {
    final Settings settingsFromDb = await ref.read(counterRepositoryProvider).getSettings();
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      settings = settingsFromDb;
      version = packageInfo.version;
    });
  }

  void _showDialog(BuildContext context, Widget title, Widget content, void Function()? confirmCallback, {bool showCancel = true, String? validateLabel}) {
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
                onPressed: () {
                  if (confirmCallback != null) {
                    confirmCallback();
                  }
                  Navigator.of(ctx).pop();
                },
                child: Text(validateLabel ?? AppLocalizations.of(context)!.validate),
              ),
            ],
          );
        });
  }

  void _exportData(BuildContext ctx) async {
    Directory? downloadDirectory;
    if (Platform.isAndroid) {
      bool? hasStoragePermission = await PermissionUtils.storagePermission();
      if (!hasStoragePermission) {
        if (!ctx.mounted) {
          return null;
        }
        _showDialog(
            ctx,
            Text(AppLocalizations.of(ctx)!.warning),
            Text(AppLocalizations.of(ctx)!.warningMsgExportData),
            null,
            showCancel: false,
            validateLabel: AppLocalizations.of(ctx)!.ok
        );
      } else {
        downloadDirectory = Directory('/storage/emulated/0/Download');
      }
    } else if (Platform.isIOS) {
      downloadDirectory = null;
    } else {
      downloadDirectory = null;
    }

    if (downloadDirectory != null) {
      List<Folder> folders = await ref.read(counterRepositoryProvider).getAllFolders();
      List<Counter> counters = await ref.read(counterRepositoryProvider).getAllCounters();
      Settings settings = await ref.read(counterRepositoryProvider).getSettings();
      List<Statistics> statistics = await ref.read(counterRepositoryProvider).getAllStatistics();
      Map<String, dynamic> json = {'settings': settings};
      if (folders.isNotEmpty) {
        json['folders'] = folders;
      }
      if (counters.isNotEmpty) {
        json['counters'] = counters;
      }
      if (statistics.isNotEmpty) {
        json['statistics'] = statistics;
      }
      final filePath = '${downloadDirectory.path}/export_counter_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.json';
      final File file = File(filePath);
      final String jsonString = jsonEncode(json);
      final File writtenFile = await file.writeAsString(jsonString);
      if (await writtenFile.exists() && ctx.mounted) {
        final SnackBar snackBar = SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white),
              const SizedBox(width: 10),
              Flexible(child: Text(AppLocalizations.of(ctx)!.successfulMsgExportData(writtenFile.path))),
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
            Flexible(child: Text(AppLocalizations.of(ctx)!.notSupportedMsgExportData)),
          ],
        ),
      );
      ScaffoldMessenger.of(ctx).showSnackBar(snackBar);
    }
  }

  void _importData(BuildContext ctx) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      final File file = File(result.files.single.path!);
      final contents = await file.readAsString();
      if (contents.isNotEmpty) {
        var data = json.decode(contents);
        if (data['settings'] != null || data['folders'] != null || data['counters'] != null) {
          if (data['settings'] != null) {
            Settings settings = Settings.fromJson(data['settings']);
            await ref.read(counterRepositoryProvider).updateSettings(settings);
          }
          if (data['folders'] != null) {
            await ref.read(counterRepositoryProvider).deleteAllFolders();
            await ref.read(counterRepositoryProvider).batchInsertFolders(List<Map<String, Object?>>.from(data['folders']));
          }
          if (data['counters'] != null) {
            await ref.read(counterRepositoryProvider).deleteAllCounters();
            await ref.read(counterRepositoryProvider).batchInsertCounters(List<Map<String, Object?>>.from(data['counters']));
          }
          if (data['statistics'] != null) {
            await ref.read(counterRepositoryProvider).deleteAllStatistics();
            await ref.read(counterRepositoryProvider).batchInsertStatistics(List<Map<String, Object?>>.from(data['statistics']));
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
                Flexible(child: Text(AppLocalizations.of(ctx)!.successfulMsgImportData)),
              ],
            ),
          );
          ScaffoldMessenger.of(ctx).showSnackBar(snackBar);
          return;
        }
      }
      if (!ctx.mounted) {
        return null;
      }
      _showDialog(
          ctx,
          Text(AppLocalizations.of(ctx)!.error),
          Text(AppLocalizations.of(ctx)!.errorMsgImportData),
          null,
          showCancel: false,
          validateLabel: AppLocalizations.of(ctx)!.ok
      );
    }
  }

  void _resetData(BuildContext context) {
    _showDialog(
      context,
      Text(AppLocalizations.of(context)!.warning),
      Text(AppLocalizations.of(context)!.warningMsgDeleteAllCounters),
          () async {
        await ref.read(counterRepositoryProvider).deleteAllFolders();
        await ref.read(counterRepositoryProvider).deleteAllCounters();
        bool result = await ref.read(counterRepositoryProvider).deleteAllStatistics();
        if (result) {
          ref.read(foldersProvider.notifier).refresh();
          if (!context.mounted) {
            return;
          }
          final SnackBar snackBar = SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white),
                const SizedBox(width: 10),
                Flexible(child: Text(AppLocalizations.of(context)!.successfulMsgDeleteAllData)),
              ],
            ),
          );
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        }
      },
    );
  }

  void _shareApplication(BuildContext context) async {
    final result = await Share.share(AppConfig.shareUrl, subject: AppLocalizations.of(context)!.shareSummary);
    if (!context.mounted) {
      return;
    }
    if (result.status == ShareResultStatus.success) {
      final SnackBar snackBar = SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 10),
            Flexible(child: Text(AppLocalizations.of(context)!.thankYouForSharing)),
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
            Flexible(child: Text(AppLocalizations.of(context)!.errorWhenRatingTheApp)),
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
            Flexible(child: Text(AppLocalizations.of(context)!.errorWhenSendingEmail)),
          ],
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  String? _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((MapEntry<String, String> e) =>
    '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
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
                  subtitle: Text(AppLocalizations.of(context)!.activateSoundsSummary),
                  value: settings.activateSounds ?? false,
                  onChanged: (value) {
                    setState(() {
                      settings.activateSounds = value;
                      ref.read(settingsProvider.notifier).updateSettings(settings);
                    });
                  },
                ),
                const Divider(),
                CheckboxListTile(
                  title: Text(AppLocalizations.of(context)!.activateVibrator),
                  subtitle: Text(AppLocalizations.of(context)!.activateVibratorSummary),
                  value: settings.activateVibrator ?? false,
                  onChanged: (value) {
                    setState(() {
                      settings.activateVibrator = value;
                      ref.read(settingsProvider.notifier).updateSettings(settings);
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
                  subtitle: Text(AppLocalizations.of(context)!.keepScreenOnSummary),
                  value: settings.keepScreenOn ?? false,
                  onChanged: (value) {
                    setState(() {
                      settings.keepScreenOn = value;
                      ref.read(settingsProvider.notifier).updateSettings(settings);
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
                      AppLocalizations.of(context)!.deleteAllCountersSummary),
                  onTap: () => _resetData(context),
                ),
                const Divider(),
                ListTile(
                  title: Text(AppLocalizations.of(context)!.exportData),
                  subtitle: Text(AppLocalizations.of(context)!.exportDataSummary),
                  onTap: () => _exportData(context),
                ),
                const Divider(),
                ListTile(
                  title: Text(AppLocalizations.of(context)!.importData),
                  subtitle: Text(AppLocalizations.of(context)!.importDataSummary),
                  onTap: () => _importData(context),
                ),
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
                  onTap: () {},
                ),
                const Divider(),
                ListTile(
                  title: Text(AppLocalizations.of(context)!.tutorial),
                  subtitle: Text(AppLocalizations.of(context)!.tutorialSummary),
                  onTap: () {},
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
                  subtitle: Text(AppLocalizations.of(context)!.contactUsSummary),
                  onTap: () => _contactUs(context),
                ),
                const Divider(),
                ListTile(
                  title: Text(AppLocalizations.of(context)!.privacyPolicy),
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SettingsSection({
    super.key,
    required this.title,
    required this.children,
  });

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
            style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        Column(
          children: children,
        ),
      ],
    );
  }
}
