import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:logging/logging.dart';
import 'screens/file_explorer_screen.dart';
import 'services/theme_service.dart';
import 'services/view_mode_service.dart';
import 'services/bookmark_service.dart';
import 'services/notification_service.dart';
import 'services/icon_size_service.dart';
import 'services/status_bar_service.dart';
import 'services/preview_panel_service.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize logging
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    // In production, you could direct this to a file or service
    // Use dart:developer log which is safe for production
    debugPrint('${record.level.name}: ${record.time}: ${record.message}');
  });
  
  // Initialize window_manager for custom window controls
  await windowManager.ensureInitialized();
  
  // Enable transparent window support
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  
  WindowOptions windowOptions = const WindowOptions(
    size: Size(1000, 800),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
    windowButtonVisibility: true,
    // Set these properties for transparent backdrop support
    fullScreen: false,
    alwaysOnTop: false,
  );
  
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
    // Set to be transparent for blur effect to work
    await windowManager.setBackgroundColor(Colors.transparent);
  });
  
  // Initialize bookmark service
  final bookmarkService = BookmarkService();
  await bookmarkService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeService()),
        ChangeNotifierProvider(create: (_) => ViewModeService()),
        ChangeNotifierProvider.value(value: bookmarkService),
        ChangeNotifierProvider(create: (_) => IconSizeService()),
        ChangeNotifierProvider(create: (_) => StatusBarService()),
        ChangeNotifierProvider(create: (_) => PreviewPanelService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Linux File Explorer',
      themeMode: themeService.themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFBBDEFB),
          foregroundColor: Colors.black87,
          elevation: 4,
        ),
        // Make scaffold background transparent for blur effect
        scaffoldBackgroundColor: Colors.transparent,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        popupMenuTheme: const PopupMenuThemeData(
          color: Color(0xFFE0E0E0),
          elevation: 4,
          textStyle: TextStyle(
            color: Colors.black87,
            fontSize: 14,
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        // Make scaffold background transparent for blur effect
        scaffoldBackgroundColor: Colors.transparent,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2C2C2C),
          foregroundColor: Colors.white,
          elevation: 4,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade700,
            foregroundColor: Colors.white,
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
        ),
        cardColor: const Color(0xFF1E1E1E),
        popupMenuTheme: const PopupMenuThemeData(
          color: Color(0xFF424242),
          elevation: 4,
          textStyle: TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
      ),
      home: const FileExplorerScreen(),
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
