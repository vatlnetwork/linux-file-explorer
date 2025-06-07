import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_service.dart';
import '../widgets/app_grid_view.dart';

class AppViewerScreen extends StatefulWidget {
  const AppViewerScreen({super.key});

  @override
  State<AppViewerScreen> createState() => _AppViewerScreenState();
}

class _AppViewerScreenState extends State<AppViewerScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'System',
    'Internet',
    'Development',
    'Graphics',
    'Media',
    'Office',
    'Games',
    'Other',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final headerColor = isDarkMode ? const Color(0xFF202124) : Colors.white;
    final borderColor =
        isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200;
    final appService = Provider.of<AppService>(context);

    return Scaffold(
      backgroundColor:
          isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFF8F9FA),
      body: Column(
        children: [
          // Modern header with subtle border
          Container(
            decoration: BoxDecoration(
              color: headerColor,
              border: Border(bottom: BorderSide(color: borderColor, width: 1)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      'Applications',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white : Colors.grey.shade800,
                        letterSpacing: 0.15,
                      ),
                    ),
                    const Spacer(),
                    // Refresh button
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Refresh Applications',
                      onPressed: () {
                        appService.refreshApps();
                      },
                      hoverColor:
                          isDarkMode
                              ? const Color(0xFF3C4043)
                              : Colors.grey.shade200,
                      splashColor:
                          isDarkMode
                              ? const Color(0xFF4C5054)
                              : Colors.grey.shade300,
                      highlightColor:
                          isDarkMode
                              ? const Color(0xFF4C5054)
                              : Colors.grey.shade300,
                    ),
                    const SizedBox(width: 8),
                    // Exit button
                    IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: 'Close',
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      hoverColor:
                          isDarkMode
                              ? const Color(0xFF3C4043)
                              : Colors.grey.shade200,
                      splashColor:
                          isDarkMode
                              ? const Color(0xFF4C5054)
                              : Colors.grey.shade300,
                      highlightColor:
                          isDarkMode
                              ? const Color(0xFF4C5054)
                              : Colors.grey.shade300,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search applications...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon:
                        _searchQuery.isNotEmpty
                            ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _searchQuery = '';
                                });
                              },
                            )
                            : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor,
                        width: 2,
                      ),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                // Category filter chips
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = _selectedCategory == category;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = selected ? category : 'All';
                            });
                          },
                          backgroundColor:
                              isDarkMode
                                  ? const Color(0xFF2C2C2C)
                                  : Colors.grey.shade100,
                          selectedColor:
                              isDarkMode
                                  ? const Color(
                                    0xFF3D4A5C,
                                  ) // Lighter blue-grey in dark mode
                                  : Theme.of(
                                    context,
                                  ).primaryColor.withAlpha((0.2 * 255).round()),
                          checkmarkColor:
                              isDarkMode
                                  ? Colors.white
                                  : Theme.of(context).primaryColor,
                          labelStyle: TextStyle(
                            color:
                                isSelected
                                    ? (isDarkMode
                                        ? Colors.white
                                        : Theme.of(context).primaryColor)
                                    : isDarkMode
                                    ? Colors.white
                                    : Colors.black87,
                            fontWeight:
                                isSelected
                                    ? FontWeight.w500
                                    : FontWeight.normal,
                          ),
                          showCheckmark: true,
                          pressElevation: 2,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color:
                                  isSelected
                                      ? (isDarkMode
                                          ? const Color(0xFF5B6A84)
                                          : Theme.of(context).primaryColor)
                                      : isDarkMode
                                      ? Colors.grey.shade800
                                      : Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Main content area with padding
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: AppGridView(
                searchQuery: _searchQuery,
                selectedCategory: _selectedCategory,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
