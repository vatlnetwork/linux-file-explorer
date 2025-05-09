import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:logging/logging.dart';
import 'screens/file_explorer_screen.dart';
import 'screens/tags_view_screen.dart';
import 'services/theme_service.dart';
import 'services/view_mode_service.dart';
import 'services/bookmark_service.dart';
import 'services/notification_service.dart';
import 'services/icon_size_service.dart';
import 'services/status_bar_service.dart';
import 'services/preview_panel_service.dart';
import 'services/app_service.dart';
import 'services/file_association_service.dart';
import 'package:flutter/services.dart';
import 'services/tags_service.dart';
import 'utils/audio_init.dart';
import 'services/drag_drop_service.dart';
import 'theme/google_theme.dart';
import 'services/tab_manager_service.dart';
import 'services/file_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize logging with more detailed configuration
  Logger.root.level = Level.ALL; // Enable all log levels in debug mode
  Logger.root.onRecord.listen((record) {
    // Format log message with timestamp, level, and source
    final message = '${record.time}: ${record.level.name}: ${record.loggerName}: ${record.message}';
    
    // In debug mode, print to console
    if (record.level >= Level.WARNING) {
      debugPrint('\x1B[31m$message\x1B[0m'); // Red for warnings and higher
    } else if (record.level >= Level.INFO) {
      debugPrint('\x1B[34m$message\x1B[0m'); // Blue for info
    } else {
      debugPrint(message); // Normal for debug and trace
    }
    
    // For production, you can implement file logging or service reporting here
  });
  
  // Create a logger for the main app
  final appLogger = Logger('App');
  appLogger.info('Application starting...');
  
  // Initialize audio support for Linux
  await initializeAudioSupport();
  appLogger.info('Audio support initialized');
  
  // Initialize window_manager for custom window controls
  await windowManager.ensureInitialized();
  appLogger.fine('Window manager initialized');
  
  // Use solid background instead of transparent window
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  
  WindowOptions windowOptions = const WindowOptions(
    size: Size(1000, 800),
    center: true,
    backgroundColor: Color(0xFF2D2D2D), // Dark gray background
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
    windowButtonVisibility: true,
    fullScreen: false,
    alwaysOnTop: false,
  );
  
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });
  
  // Initialize bookmark service
  final bookmarkService = BookmarkService();
  await bookmarkService.init();

  // Initialize app service
  final appService = AppService();
  await appService.init();
  
  // Initialize file association service
  final fileAssociationService = FileAssociationService();
  await fileAssociationService.init();
  
  // Initialize tags service
  final tagsService = TagsService();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeService()),
        ChangeNotifierProvider(create: (_) => ViewModeService()),
        ChangeNotifierProvider.value(value: bookmarkService),
        ChangeNotifierProvider(create: (_) => IconSizeService()),
        ChangeNotifierProvider(create: (_) => StatusBarService()),
        ChangeNotifierProvider(create: (_) => PreviewPanelService()),
        ChangeNotifierProvider.value(value: appService),
        ChangeNotifierProvider.value(value: fileAssociationService),
        ChangeNotifierProvider.value(value: tagsService),
        ChangeNotifierProvider(create: (_) => DragDropService()),
        ChangeNotifierProvider(create: (_) => TabManagerService()),
        Provider(create: (_) => FileService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Linux File Manager',
      theme: GoogleTheme.lightTheme,
      darkTheme: GoogleTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: const FileExplorerScreen(),
      routes: {
        TagsViewScreen.routeName: (context) => const TagsViewScreen(),      },
      scaffoldMessengerKey: NotificationService.messengerKey,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
