import 'dart:math';

import 'package:counter/models/settings.dart';
import 'package:counter/models/sorting_options.dart';
import 'package:counter/providers/counter_repository_provider.dart';
import 'package:counter/providers/counters_provider.dart';
import 'package:counter/providers/settings_provider.dart';
import 'package:counter/repository/counter_repository.dart';
import 'package:counter/widgets/non_dismissible_popup_menu_item.dart';
import 'package:flutter/material.dart';
import 'package:counter/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CountersPopupMenu extends ConsumerStatefulWidget {
  const CountersPopupMenu({super.key});

  @override
  ConsumerState<CountersPopupMenu> createState() => _CountersPopupMenuState();
}

enum _PopupOption {
  toggleView,
  custom,
  alphabetical,
  counterValue,
  creationDate,
}

class _CountersPopupMenuState extends ConsumerState<CountersPopupMenu> {
  final double _appBarHeight = AppBar().preferredSize.height;
  Settings? _settings;

  @override
  void initState() {
    super.initState();
    initSettings();
  }

  void initSettings() async {
    final CounterRepository counterRepository = ref.read(
      counterRepositoryProvider,
    );
    counterRepository.getSettings().then(
      (Settings settings) => setState(() {
        _settings = settings;
      }),
    );
  }

  CheckedPopupMenuItem<_PopupOption> _buildCheckedPopupMenuItemWidget(
    String title,
    FaIconData? iconData,
    _PopupOption option, {
    bool rotate = false,
    bool checked = false,
  }) {
    var popupMenuItem = CheckedPopupMenuItem<_PopupOption>(
      checked: checked,
      value: option,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(title)),
          if (iconData != null)
            rotate
                ? Transform.rotate(angle: pi / 2, child: FaIcon(iconData))
                : FaIcon(iconData),
        ],
      ),
    );
    return popupMenuItem;
  }

  @override
  Widget build(BuildContext context) {
    bool customChecked = false;
    bool alphabeticalChecked = false;
    bool counterCountChecked = false;
    bool creationDateChecked = false;
    FaIconData? alphabeticalIcon;
    FaIconData? counterCountIcon;
    FaIconData? creationDateIcon;
    String alphabeticalTitle = AppLocalizations.of(context)!.alphabeticalOrder;
    String valueTitle = AppLocalizations.of(context)!.counterCountOrder;
    String creationDateTitle = AppLocalizations.of(context)!.creationDate;
    if (_settings != null && _settings!.counterSorting != null) {
      customChecked = _settings!.counterSorting == SortingOptions.custom;
      alphabeticalChecked =
          _settings!.counterSorting == SortingOptions.alphabeticalAsc ||
          _settings!.counterSorting == SortingOptions.alphabeticalDesc;
      counterCountChecked =
          _settings!.counterSorting == SortingOptions.valueAsc ||
          _settings!.counterSorting == SortingOptions.valueDesc;
      creationDateChecked =
          _settings!.counterSorting == SortingOptions.creationDateAsc ||
          _settings!.counterSorting == SortingOptions.creationDateDesc;
      switch (_settings!.counterSorting!) {
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
          valueTitle = AppLocalizations.of(context)!
              .counterCountWithSuffix('(1-9)');
          break;
        case SortingOptions.valueDesc:
          counterCountIcon = FontAwesomeIcons.arrowDown19;
          valueTitle = AppLocalizations.of(context)!
              .counterCountWithSuffix('(9-1)');
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
      icon: const FaIcon(FontAwesomeIcons.sliders),
      onSelected: (_PopupOption value) {
        onMenuItemSelected(value);
      },
      offset: Offset(0.0, _appBarHeight),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(15.0)),
      ),
      itemBuilder: (ctx) {
        return [
          _buildCheckedPopupMenuItemWidget(
            AppLocalizations.of(context)!.compactView,
            FontAwesomeIcons.tableCellsLarge,
            _PopupOption.toggleView,
            checked: _settings != null && _settings!.counterCompactView != null
                ? _settings!.counterCompactView!
                : false,
          ),
          const PopupMenuDivider(),
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
            _PopupOption.counterValue,
            checked: counterCountChecked,
          ),
          _buildCheckedPopupMenuItemWidget(
            creationDateTitle,
            creationDateIcon,
            _PopupOption.creationDate,
            checked: creationDateChecked,
          ),
        ];
      },
    );
  }

  void onMenuItemSelected(_PopupOption option) async {
    if (_settings != null) {
      switch (option) {
        case _PopupOption.toggleView:
          if (_settings!.counterCompactView == true) {
            _settings!.counterCompactView = false;
          } else {
            _settings!.counterCompactView = true;
          }
          break;
        case _PopupOption.custom:
          if (_settings!.counterSorting != SortingOptions.custom) {
            _settings!.counterSorting = SortingOptions.custom;
          } else {
            _settings!.counterSorting = null;
          }
          break;
        case _PopupOption.alphabetical:
          if (_settings!.counterSorting != SortingOptions.alphabeticalAsc &&
              _settings!.counterSorting != SortingOptions.alphabeticalDesc) {
            _settings!.counterSorting = SortingOptions.alphabeticalAsc;
          } else if (_settings!.counterSorting ==
              SortingOptions.alphabeticalAsc) {
            _settings!.counterSorting = SortingOptions.alphabeticalDesc;
          } else {
            _settings!.counterSorting = null;
          }
          break;
        case _PopupOption.counterValue:
          if (_settings!.counterSorting != SortingOptions.valueAsc &&
              _settings!.counterSorting != SortingOptions.valueDesc) {
            _settings!.counterSorting = SortingOptions.valueAsc;
          } else if (_settings!.counterSorting == SortingOptions.valueAsc) {
            _settings!.counterSorting = SortingOptions.valueDesc;
          } else {
            _settings!.counterSorting = null;
          }
          break;
        case _PopupOption.creationDate:
          if (_settings!.counterSorting != SortingOptions.creationDateAsc &&
              _settings!.counterSorting != SortingOptions.creationDateDesc) {
            _settings!.counterSorting = SortingOptions.creationDateAsc;
          } else if (_settings!.counterSorting ==
              SortingOptions.creationDateAsc) {
            _settings!.counterSorting = SortingOptions.creationDateDesc;
          } else {
            _settings!.counterSorting = null;
          }
          break;
      }
      setState(() {
        _settings = Settings.copy(_settings!);
      });
      await ref.read(settingsProvider.notifier).updateSettings(_settings!);
      ref.read(countersProvider.notifier).refresh();
    }
  }
}
