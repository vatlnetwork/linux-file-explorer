import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConfigSettings extends StatefulWidget {
  const ConfigSettings({super.key});

  @override
  State<ConfigSettings> createState() => _ConfigSettingsState();
}

class _ConfigSettingsState extends State<ConfigSettings> {
  late bool _useLastVisitedDir;
  String? _customDirectory;
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await _prefs;
    setState(() {
      _useLastVisitedDir = prefs.getBool('use_last_visited_dir') ?? true;
      _customDirectory = prefs.getString('custom_start_directory');
    });
  }

  Future<void> _selectDirectory() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) {
      final prefs = await _prefs;
      await prefs.setString('custom_start_directory', selectedDirectory);
      setState(() {
        _customDirectory = selectedDirectory;
      });
    }
  }

  Future<void> _clearCustomDirectory() async {
    final prefs = await _prefs;
    await prefs.remove('custom_start_directory');
    setState(() {
      _customDirectory = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const Text(
          'Startup Directory',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Radio<bool>(
                      value: true,
                      groupValue: _useLastVisitedDir,
                      onChanged: (bool? value) async {
                        if (value != null) {
                          final prefs = await _prefs;
                          await prefs.setBool('use_last_visited_dir', true);
                          setState(() {
                            _useLastVisitedDir = true;
                          });
                        }
                      },
                    ),
                    const Text('Open last visited directory'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Radio<bool>(
                      value: false,
                      groupValue: _useLastVisitedDir,
                      onChanged: (bool? value) async {
                        if (value != null) {
                          final prefs = await _prefs;
                          await prefs.setBool('use_last_visited_dir', false);
                          setState(() {
                            _useLastVisitedDir = false;
                          });
                        }
                      },
                    ),
                    const Text('Open custom directory:'),
                  ],
                ),
                if (!_useLastVisitedDir) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const SizedBox(width: 40), // Match radio button indentation
                      Expanded(
                        child: Text(
                          _customDirectory ?? 'No directory selected',
                          style: TextStyle(
                            color: _customDirectory != null
                                ? Theme.of(context).textTheme.bodyLarge?.color
                                : Theme.of(context).textTheme.bodySmall?.color,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: _selectDirectory,
                        child: const Text('Browse'),
                      ),
                      if (_customDirectory != null) ...[
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: _clearCustomDirectory,
                          child: const Text('Clear'),
                        ),
                      ],
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  _useLastVisitedDir
                      ? 'The file explorer will open to the last directory you were viewing.'
                      : _customDirectory != null
                          ? 'The file explorer will always open to the selected directory.'
                          : 'Please select a directory to open on startup.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
