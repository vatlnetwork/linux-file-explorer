import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/theme_service.dart';
import 'services/tags_service.dart';
import 'services/file_service.dart';
import 'services/bookmark_service.dart';
import 'services/tab_manager_service.dart';
import 'services/disk_usage_widget_service.dart';
import 'services/app_service.dart';
import 'services/preview_panel_service.dart';
import 'services/view_mode_service.dart';
import 'services/status_bar_service.dart';
import 'services/icon_size_service.dart';
import 'services/drag_drop_service.dart';
import 'services/settings_view_mode_service.dart';
import 'services/file_association_service.dart';
import 'widgets/settings/addons_settings.dart';
import 'screens/file_explorer_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/disk_manager_screen.dart';
import 'screens/tags_view_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize media support for Linux
  await initializeMediaSupport();

  // Set window title and size
  await setWindowTitle('File Explorer');
  await setWindowSize(const Size(1200, 800));

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Core services
        ChangeNotifierProvider(create: (_) => ThemeService()),
        ChangeNotifierProvider(create: (_) => TagsService()..init()),
        ChangeNotifierProvider(create: (_) => DiskUsageWidgetService()),
        ChangeNotifierProvider(create: (_) => AppService()),
        ChangeNotifierProvider(create: (_) => PreviewPanelService()),
        ChangeNotifierProvider(create: (_) => ViewModeService()),
        ChangeNotifierProvider(create: (_) => StatusBarService()),
        ChangeNotifierProvider(create: (_) => IconSizeService()),
        ChangeNotifierProvider(create: (_) => ContextMenuSettings()),
        ChangeNotifierProvider(create: (_) => DragDropService()),
        ChangeNotifierProvider(create: (_) => SettingsViewModeService()),
        ChangeNotifierProvider(create: (_) => FileAssociationService()),

        // Dependent services
        ChangeNotifierProvider(create: (_) => BookmarkService()..init()),
        ChangeNotifierProvider(create: (_) => TabManagerService()),
        ChangeNotifierProxyProvider<TagsService, FileService>(
          create: (context) => FileService(context.read<TagsService>()),
          update: (context, tagsService, fileService) {
            return FileService(tagsService);
          },
        ),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, _) {
          return MaterialApp(
            title: 'File Explorer',
            theme: themeService.getLightTheme(),
            darkTheme: themeService.getDarkTheme(),
            themeMode: themeService.themeMode,
            home: const FileExplorerScreen(),
            routes: {
              '/settings': (context) => const SettingsScreen(),
              '/disk-manager': (context) => const DiskManagerScreen(),
              '/tags': (context) => const TagsViewScreen(),
            },
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

Future<void> initializeMediaSupport() async {
  // Initialize media support for Linux
}

Future<void> setWindowTitle(String title) async {
  // Set window title
}

Future<void> setWindowSize(Size size) async {
  // Set window size
}
