import 'package:counterpp/screens/folders_screen.dart';
import 'package:counterpp/screens/settings_screen.dart';
import 'package:counterpp/widgets/counter_widget.dart';
import 'package:counterpp/widgets/folder_dialog.dart';
import 'package:counterpp/widgets/folders_app_bar.dart';
import 'package:counterpp/widgets/loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:counterpp/l10n/app_localizations.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

const HOME_TAB_INDEX = 0;
const FOLDER_TAB_INDEX = 1;
const SETTINGS_TAB_INDEX = 2;

// typedef resetCounterBuilder = void Function(BuildContext context, void Function() resetCounter);

class TabsScreen extends StatefulWidget {
  const TabsScreen({super.key});

  @override
  State<TabsScreen> createState() => _TabsScreenState();
}

class _TabsScreenState extends State<TabsScreen> {
  void Function()? _resetCounter;
  int _selectedIndex = 0;
  bool _editMode = false;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    PreferredSizeWidget appBar;
    Widget? floatingActionButton;
    if (_selectedIndex == HOME_TAB_INDEX) {
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
          )
        ],
      );
    } else if (_selectedIndex == FOLDER_TAB_INDEX) {
      body = FoldersScreen(editMode: _editMode);
      appBar = FoldersAppBar(onEditModeChange: (bool editMode) {
        setState(() {
          _editMode = editMode;
        });
      });
      floatingActionButton = FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (ctx) => const FolderDialog(),
          );
        },
        child: const Icon(FontAwesomeIcons.plus),
      );
    } else if (_selectedIndex == SETTINGS_TAB_INDEX) {
      body = const SettingsScreen();
      appBar = AppBar(
        title: Text(AppLocalizations.of(context)!.settings),
      );
    } else {
      appBar = AppBar(
        title: const Text('Counter++'),
      );
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
      floatingActionButton: floatingActionButton
    );
  }
}
