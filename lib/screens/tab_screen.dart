import 'package:counter/providers/counter_repository_provider.dart';
import 'package:counter/screens/folders_screen.dart';
import 'package:counter/screens/settings_screen.dart';
import 'package:counter/widgets/counter_widget.dart';
import 'package:counter/widgets/folder_dialog.dart';
import 'package:counter/widgets/folders_app_bar.dart';
import 'package:counter/widgets/loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:counter/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

const homeTabIndex = 0;
const folderTabIndex = 1;
const settingsTabIndex = 2;

// typedef resetCounterBuilder = void Function(BuildContext context, void Function() resetCounter);

class TabsScreen extends ConsumerStatefulWidget {
  final int selectedTabIndex;

  const TabsScreen({super.key, this.selectedTabIndex = 0});

  @override
  ConsumerState<TabsScreen> createState() => _TabsScreenState();
}

class _TabsScreenState extends ConsumerState<TabsScreen> {
  void Function()? _resetCounter;
  late int _selectedIndex;
  bool _editMode = false;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedTabIndex;
  }

  void _onItemTapped(int index) {
    ref.read(counterRepositoryProvider).updateLastOpenedTabIndex(index);
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    PreferredSizeWidget appBar;
    Widget? floatingActionButton;
    if (_selectedIndex == homeTabIndex) {
      body = CounterWidget(
        counterId: 1,
        builder: (BuildContext context, void Function() resetCounter) {
          _resetCounter = resetCounter;
        },
      );
      appBar = AppBar(
        title: const Text('Counter++'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.settings_backup_restore_rounded),
            onPressed: () {
              if (_resetCounter != null) {
                _resetCounter!.call();
              }
            },
          ),
        ],
      );
    } else if (_selectedIndex == folderTabIndex) {
      body = FoldersScreen(editMode: _editMode);
      appBar = FoldersAppBar(
        onEditModeChange: (bool editMode) {
          setState(() {
            _editMode = editMode;
          });
        },
      );
      floatingActionButton = FloatingActionButton(
        onPressed: () {
          showDialog(context: context, builder: (ctx) => const FolderDialog());
        },
        child: const FaIcon(FontAwesomeIcons.plus),
      );
    } else if (_selectedIndex == settingsTabIndex) {
      body = const SettingsScreen();
      appBar = AppBar(title: Text(AppLocalizations.of(context)!.settings));
    } else {
      appBar = AppBar(title: const Text('Counter++'));
      body = const LoadingIndicator();
    }

    return Scaffold(
      appBar: appBar,
      body: SafeArea(child: body),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: AppLocalizations.of(context)!.home,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.folder),
            label: AppLocalizations.of(context)!.folders,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings),
            label: AppLocalizations.of(context)!.settings,
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).textTheme.bodyLarge!.color,
        showUnselectedLabels: true,
        onTap: _onItemTapped,
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}
