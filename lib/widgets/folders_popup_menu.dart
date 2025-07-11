import 'dart:math';

import 'package:counterpp/models/settings.dart';
import 'package:counterpp/models/sorting_options.dart';
import 'package:counterpp/providers/counter_repository_provider.dart';
import 'package:counterpp/providers/folders_provider.dart';
import 'package:counterpp/providers/settings_provider.dart';
import 'package:counterpp/repository/counter_repository.dart';
import 'package:counterpp/widgets/non_dismissible_popup_menu_item.dart';
import 'package:flutter/material.dart';
import 'package:counterpp/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class FoldersPopupMenu extends ConsumerStatefulWidget {
  const FoldersPopupMenu({super.key});

  @override
  ConsumerState<FoldersPopupMenu> createState() =>
      _FoldersPopupMenuState();
}

enum _PopupOption { custom, alphabetical, counterCount, creationDate }

class _FoldersPopupMenuState extends ConsumerState<FoldersPopupMenu> {
  final double _appBarHeight = AppBar().preferredSize.height;
  Settings? _settings;

  @override
  void initState() {
    super.initState();
    initSettings();
  }

  void initSettings() async {
    final CounterRepository counterRepository = ref.read(counterRepositoryProvider);
    counterRepository.getSettings().then((Settings settings) => setState(() {
      _settings = settings;
    }));
  }

  CheckedPopupMenuItem<_PopupOption> _buildCheckedPopupMenuItemWidget(
      String title, IconData? iconData, _PopupOption option,
      {bool rotate = false, bool checked = false}) {
    var popupMenuItem = CheckedPopupMenuItem<_PopupOption>(
        checked: checked,
        value: option,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(title)),
            if (iconData != null)
              rotate
                  ? Transform.rotate(angle: pi / 2, child: Icon(iconData))
                  : Icon(iconData),
          ],
        ));
    return popupMenuItem;
  }

  @override
  Widget build(BuildContext context) {
    bool customChecked = false;
    bool alphabeticalChecked = false;
    bool counterCountChecked = false;
    bool creationDateChecked = false;
    IconData? alphabeticalIcon;
    IconData? counterCountIcon;
    IconData? creationDateIcon;
    String alphabeticalTitle = AppLocalizations.of(context)!.alphabeticalOrder;
    String valueTitle = AppLocalizations.of(context)!.counterCountOrder;
    String creationDateTitle = AppLocalizations.of(context)!.creationDate;
    if (_settings != null && _settings!.folderSorting != null) {
      customChecked = _settings!.folderSorting == SortingOptions.custom;
      alphabeticalChecked =
          _settings!.folderSorting == SortingOptions.alphabeticalAsc ||
              _settings!.folderSorting == SortingOptions.alphabeticalDesc;
      counterCountChecked =
          _settings!.folderSorting == SortingOptions.valueAsc ||
              _settings!.folderSorting == SortingOptions.valueDesc;
      creationDateChecked =
          _settings!.folderSorting == SortingOptions.creationDateAsc ||
              _settings!.folderSorting == SortingOptions.creationDateDesc;
      switch (_settings!.folderSorting!) {
        case SortingOptions.alphabeticalAsc:
          alphabeticalIcon = FontAwesomeIcons.arrowUpZA;
          alphabeticalTitle = AppLocalizations.of(context)!
              .alphabeticalOrderWithSuffix('(A-Z)');
          break;
        case SortingOptions.alphabeticalDesc:
          alphabeticalIcon = FontAwesomeIcons.arrowDownZA;
          alphabeticalTitle = AppLocalizations.of(context)!
              .alphabeticalOrderWithSuffix('(Z-A)');
          break;
        case SortingOptions.valueAsc:
          counterCountIcon = FontAwesomeIcons.arrowUp91;
          valueTitle = AppLocalizations.of(context)!.counterCountWithSuffix('(1-9)');
          break;
        case SortingOptions.valueDesc:
          counterCountIcon = FontAwesomeIcons.arrowDown19;
          valueTitle = AppLocalizations.of(context)!.counterCountWithSuffix('(9-1)');
          break;
        case SortingOptions.creationDateAsc:
          creationDateIcon = FontAwesomeIcons.arrowUp;
          break;
        case SortingOptions.creationDateDesc:
          creationDateIcon = FontAwesomeIcons.arrowDown;
          break;
        case SortingOptions.custom:
          break;
      }
    }

    return PopupMenuButton<_PopupOption>(
        elevation: 10,
        icon: const Icon(FontAwesomeIcons.sliders),
        onSelected: (_PopupOption value) {
          onMenuItemSelected(value);
        },
        offset: Offset(0.0, _appBarHeight),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(15.0))),
        itemBuilder: (ctx) {
          return [
            NonDismissiblePopupMenuItem(
              child: Text(
                AppLocalizations.of(context)!.sortBy,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            _buildCheckedPopupMenuItemWidget(
              AppLocalizations.of(context)!.custom,
              null,
              _PopupOption.custom,
              checked: customChecked,
            ),
            _buildCheckedPopupMenuItemWidget(
              alphabeticalTitle,
              alphabeticalIcon,
              _PopupOption.alphabetical,
              checked: alphabeticalChecked,
            ),
            _buildCheckedPopupMenuItemWidget(
              valueTitle,
              counterCountIcon,
              _PopupOption.counterCount,
              checked: counterCountChecked,
            ),
            _buildCheckedPopupMenuItemWidget(
              creationDateTitle,
              creationDateIcon,
              _PopupOption.creationDate,
              checked: creationDateChecked,
            ),
          ];
        });
  }

  void onMenuItemSelected(_PopupOption option) async {
    if (_settings != null) {
      switch (option) {
        case _PopupOption.custom:
          if (_settings!.folderSorting != SortingOptions.custom) {
            _settings!.folderSorting = SortingOptions.custom;
          } else {
            _settings!.folderSorting = null;
          }
          break;
        case _PopupOption.alphabetical:
          if (_settings!.folderSorting != SortingOptions.alphabeticalAsc &&
              _settings!.folderSorting != SortingOptions.alphabeticalDesc) {
            _settings!.folderSorting = SortingOptions.alphabeticalAsc;
          } else if (_settings!.folderSorting ==
              SortingOptions.alphabeticalAsc) {
            _settings!.folderSorting = SortingOptions.alphabeticalDesc;
          } else {
            _settings!.folderSorting = null;
          }
          break;
        case _PopupOption.counterCount:
          if (_settings!.folderSorting != SortingOptions.valueAsc &&
              _settings!.folderSorting != SortingOptions.valueDesc) {
            _settings!.folderSorting = SortingOptions.valueAsc;
          } else if (_settings!.folderSorting == SortingOptions.valueAsc) {
            _settings!.folderSorting = SortingOptions.valueDesc;
          } else {
            _settings!.folderSorting = null;
          }
          break;
        case _PopupOption.creationDate:
          if (_settings!.folderSorting != SortingOptions.creationDateAsc &&
              _settings!.folderSorting != SortingOptions.creationDateDesc) {
            _settings!.folderSorting = SortingOptions.creationDateAsc;
          } else if (_settings!.folderSorting ==
              SortingOptions.creationDateAsc) {
            _settings!.folderSorting = SortingOptions.creationDateDesc;
          } else {
            _settings!.folderSorting = null;
          }
          break;
      }
      setState(() {
        _settings = Settings.copy(_settings!);
      });
      await ref.read(settingsProvider.notifier).updateSettings(_settings!);
      ref.read(foldersProvider.notifier).refresh();
    }
  }
}
