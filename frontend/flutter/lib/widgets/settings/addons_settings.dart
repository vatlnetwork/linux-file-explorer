import 'package:flutter/material.dart';

class AddonsSettings extends StatefulWidget {
  const AddonsSettings({super.key});

  @override
  State<AddonsSettings> createState() => _AddonsSettingsState();
}

class _AddonsSettingsState extends State<AddonsSettings> {
  final Map<String, bool> _contextMenuItems = {
    'Open in Terminal': true,
    'Open with Code Editor': true,
    'Copy Path': true,
    'Create Archive': true,
    'Extract Archive': true,
    'Calculate Hash': true,
    'Share': true,
    'Properties': true,
  };

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Addons',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          // Context Menu Items
          _buildSection(
            title: 'Context Menu Items',
            subtitle: 'Choose which items appear in the right-click menu',
            child: Card(
              elevation: 0,
              color: isDarkMode ? const Color(0xFF2C2C2C) : Colors.grey.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color:
                      isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
                ),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _contextMenuItems.length,
                separatorBuilder:
                    (context, index) => Divider(
                      height: 1,
                      color:
                          isDarkMode
                              ? Colors.grey.shade800
                              : Colors.grey.shade300,
                    ),
                itemBuilder: (context, index) {
                  final item = _contextMenuItems.keys.elementAt(index);
                  final isEnabled = _contextMenuItems[item]!;

                  return SwitchListTile(
                    title: Text(
                      item,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    value: isEnabled,
                    onChanged: (value) {
                      setState(() {
                        _contextMenuItems[item] = value;
                      });
                    },
                    activeColor: Theme.of(context).primaryColor,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color:
                  Theme.of(context).brightness == Brightness.dark
                      ? Colors.white70
                      : Colors.grey.shade600,
            ),
          ),
        ],
        const SizedBox(height: 16),
        child,
      ],
    );
  }
}
