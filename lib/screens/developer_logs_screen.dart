import 'package:counter/l10n/app_localizations.dart';
import 'package:counter/utils/logging_service.dart';
import 'package:flutter/material.dart';

class DeveloperLogsScreen extends StatefulWidget {
  const DeveloperLogsScreen({super.key});

  @override
  State<DeveloperLogsScreen> createState() => _DeveloperLogsScreenState();
}

class _DeveloperLogsScreenState extends State<DeveloperLogsScreen> {
  String _logs = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    if (!_isLoading) {
      setState(() {
        _isLoading = true;
      });
    }

    final logs = await LoggingService().readLogs();
    if (!mounted) {
      return;
    }
    setState(() {
      _logs = logs;
      _isLoading = false;
    });
  }

  Future<void> _clearLogs() async {
    await LoggingService().clearLogs();
    if (!mounted) {
      return;
    }
    setState(() {
      _logs = '';
    });
    final snackBar = SnackBar(
      content: Row(
        children: [
          const Icon(Icons.delete_outline, color: Colors.white),
          const SizedBox(width: 10),
          Flexible(
            child: Text(AppLocalizations.of(context)!.developerLogsCleared),
          ),
        ],
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    final labels = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(labels.developerLogsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadLogs,
            tooltip: labels.developerLogsRefresh,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _logs.isEmpty
                ? null
                : () async {
                    await _clearLogs();
                  },
            tooltip: labels.developerLogsClear,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadLogs,
              child: _logs.trim().isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            labels.developerLogsEmpty,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    )
                  : ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      children: [
                        SelectableText(
                          _logs,
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                      ],
                    ),
            ),
    );
  }
}
