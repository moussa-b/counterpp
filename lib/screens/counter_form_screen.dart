import 'package:counterpp/models/counter.dart';
import 'package:counterpp/models/folder.dart';
import 'package:counterpp/providers/counter_repository_provider.dart';
import 'package:counterpp/providers/counters_provider.dart';
import 'package:counterpp/providers/folders_provider.dart';
import 'package:counterpp/repository/counter_repository.dart';
import 'package:counterpp/utils/utils.dart';
import 'package:counterpp/widgets/folder_dialog.dart';
import 'package:counterpp/widgets/loading_indicator.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:counterpp/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CounterFormScreen extends ConsumerStatefulWidget {
  final int? counterId;
  final Folder? currentFolder;

  const CounterFormScreen({super.key, this.counterId, this.currentFolder});

  @override
  ConsumerState<CounterFormScreen> createState() =>
      _CounterFormScreenState();
}

class _CounterFormScreenState extends ConsumerState<CounterFormScreen> {
  final _formKey = GlobalKey<FormState>();
  Counter? _formCounter;
  int? _selectedFolderId;
  Color? _selectedColor;
  int _nameLength = 0;

  bool get isEdition {
    return widget.counterId != null && widget.counterId! > 0;
  }

  void _saveCounter(BuildContext context, WidgetRef ref) {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      if (isEdition) {
        ref.read(countersProvider.notifier).updateCounter(_formCounter!).then((value) => Navigator.of(context).pop());
      } else {
        ref.read(countersProvider.notifier).addCounter(_formCounter!).then((value) => Navigator.of(context).pop());
      }
    }
  }

  void _resetForm() {
    _formKey.currentState!.reset();
  }

  @override
  void initState() {
    super.initState();
    initForm();
  }

  void initForm() async {
    Folder? initialFolder;
    Counter? counter;
    if (isEdition) {
      final CounterRepository counterRepository = ref.read(counterRepositoryProvider);
      counter = await counterRepository.getCounterById(widget.counterId!);
      initialFolder = counter.folder!;
      _nameLength = counter.name!.length;
      if (counter.color != null && counter.color!.isNotEmpty) {
        _selectedColor = Utils.hexToColor(counter.color!);
      }
    } else {
      counter = Counter();
      initialFolder = widget.currentFolder;
    }
    setState(() {
      _formCounter = counter;
      if (initialFolder != null &&
          initialFolder.id != null &&
          initialFolder.id! > 0) {
        _selectedFolderId = initialFolder.id!;
        _formCounter!.folder = initialFolder;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    AsyncValue<List<Folder>> folders = ref.watch(foldersProvider);
    final Widget separator = SizedBox(height: MediaQuery.of(context).size.width * 0.05);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdition
            ? AppLocalizations.of(context)!.editCounter
            : AppLocalizations.of(context)!.createNewCounter),
      ),
      body: SafeArea(
        child: _formCounter == null || folders.isLoading
            ? const LoadingIndicator()
            : SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      maxLength: 50,
                      initialValue: _formCounter!.name,
                      buildCounter: (context, {required currentLength, required isFocused, required maxLength}) => null,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        suffixText: "$_nameLength/50",
                        labelText: AppLocalizations.of(context)!.counterName,
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                      ),
                      onChanged: (val) {
                        setState(() {
                          _nameLength = val.length;
                        });
                      },
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty ||
                            value.trim().length <= 1 ||
                            value.trim().length > 50) {
                          return AppLocalizations.of(context)!
                              .pleaseEnterValidValue;
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _formCounter!.name = value;
                      },
                    ),
                    separator,
                    TextFormField(
                      initialValue: _formCounter!.counterLimit != null && _formCounter!.counterLimit! > 0 ? _formCounter!.counterLimit?.toString() : null,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: false,
                        signed: false,
                      ),
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: AppLocalizations.of(context)!.limit,
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                      ),
                      validator: (value) {
                        if (value != null &&
                            value.trim().isNotEmpty &&
                            (int.tryParse(value) == null ||
                                int.tryParse(value)! <= 0)) {
                          return AppLocalizations.of(context)!
                              .pleaseEnterValidValue;
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _formCounter!.counterLimit =
                        value != null && value.trim().isNotEmpty
                            ? int.parse(value)
                            : 0;
                      },
                    ),
                    separator,
                    TextFormField(
                      initialValue: _formCounter!.counterCount != null && _formCounter!.counterCount! > 0 ? _formCounter!.counterCount?.toString() : null,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: false,
                        signed: false,
                      ),
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: AppLocalizations.of(context)!.value,
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                      ),
                      validator: (value) {
                        if (value != null &&
                            value.trim().isNotEmpty &&
                            (int.tryParse(value) == null ||
                                int.tryParse(value)! <= 0)) {
                          return AppLocalizations.of(context)!
                              .pleaseEnterValidValue;
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _formCounter!.counterCount =
                        value != null && value.trim().isNotEmpty
                            ? int.parse(value)
                            : 0;
                      },
                    ),
                    separator,
                    TextFormField(
                      initialValue: _formCounter!.step != null && _formCounter!.step! > 0 ? _formCounter!.step?.toString() : null,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: false,
                        signed: false,
                      ),
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: AppLocalizations.of(context)!.incrementationValue,
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                      ),
                      validator: (value) {
                        if (value != null &&
                            value.trim().isNotEmpty &&
                            (int.tryParse(value) == null ||
                                int.tryParse(value)! <= 0)) {
                          return AppLocalizations.of(context)!
                              .pleaseEnterValidValue;
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _formCounter!.step =
                        value != null && value.trim().isNotEmpty
                            ? int.parse(value)
                            : 0;
                      },
                    ),
                    separator,
                    DropdownMenu<int>(
                        expandedInsets: const EdgeInsets.all(0),
                        initialSelection: _selectedFolderId,
                        label: Text(AppLocalizations.of(context)!.folder),
                        onSelected: (int? folderId) async {
                          if (folderId != null) {
                            setState(() {
                              _selectedFolderId = folderId;
                            });
                            if (folderId > 0) {
                              _formCounter!.folder = folders.value!.firstWhere(
                                      (Folder folder) => folder.id == folderId);
                            } else {
                              Folder? createdFolder =
                              await showDialog<Folder?>(
                                context: context,
                                builder: (ctx) => const FolderDialog(),
                              );
                              if (createdFolder != null &&
                                  createdFolder.id != null &&
                                  createdFolder.id! > 0) {
                                _formCounter!.folder = createdFolder;
                                setState(() {
                                  _selectedFolderId = createdFolder.id;
                                });
                              } else {
                                setState(() {
                                  _selectedFolderId =
                                      widget.currentFolder!.id;
                                  _formCounter!.folder = widget.currentFolder;
                                });
                              }
                            }
                          }
                        },
                        dropdownMenuEntries: [
                          DropdownMenuEntry<int>(
                            value: 0,
                            label: AppLocalizations.of(context)!.addFolder,
                          ),
                          ...folders.value!
                              .map<DropdownMenuEntry<int>>((Folder folder) {
                            return DropdownMenuEntry<int>(
                                value: folder.id!, label: folder.name!);
                          }),
                        ]),
                    separator,
                    TextFormField(
                      initialValue: _formCounter!.note,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: AppLocalizations.of(context)!.notes,
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                      ),
                      minLines: 3,
                      maxLines: 4,
                      keyboardType: TextInputType.multiline,
                      textCapitalization: TextCapitalization.sentences,
                      onSaved: (value) {
                        _formCounter!.note = value;
                      },
                    ),
                    separator,
                    InputDecorator(
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: AppLocalizations.of(context)!.color,
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                      ),
                      child: ColorPicker(
                        color: _selectedColor ?? Utils.hexToColor('#ff2196f3'), // blue
                        onColorChanged: (Color color) {
                          _formCounter!.color = '#${color.value.toRadixString(16)}';
                        },
                        width: 44,
                        height: 44,
                        borderRadius: 22,
                        enableShadesSelection: false,
                        pickersEnabled: const <ColorPickerType, bool>{
                          ColorPickerType.primary: true,
                          ColorPickerType.accent: false,
                        },
                      ),
                    ),
                    separator,
                    Row(
                      children: [
                        TextButton(
                          onPressed: _resetForm,
                          child: Text(AppLocalizations.of(context)!.reset),
                        ),
                        ElevatedButton(
                          onPressed: () => _saveCounter(context, ref),
                          child: Text(AppLocalizations.of(context)!.validate),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
