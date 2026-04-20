import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:futsalmobile/pages/favoritesPage/favorites_page.dart';
import 'package:futsalmobile/pages/homePage/home_page.dart';
import 'package:futsalmobile/pages/leaguePage/league_page.dart';
import 'package:futsalmobile/pages/matchesPage/match_page.dart';
import 'package:futsalmobile/pages/newsPage/news_page.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:futsalmobile/services/auth_service.dart';
import 'package:futsalmobile/services/cache_service.dart';
import 'package:futsalmobile/services/favorites_service.dart';
import 'package:futsalmobile/services/firebase_services.dart';
import 'package:futsalmobile/services/search_service.dart';
import 'package:futsalmobile/widgets/bottom_navigation_bar.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  // Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Enable Firestore disk persistence (free cache for all previously-fetched docs)
  FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'main',
  ).settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // Anonymous auth — gives every user a stable UID for favorites
  try {
    await AuthService.signInAnonymously();
  } catch (_) {}

  // Request notification permission and initialize FCM
  await FirebaseMessaging.instance.requestPermission();
  await FirebaseMessaging.instance.getToken();

  // Re-subscribe to FCM topics (lost on reinstall/clear)
  FavoritesService().restoreSubscriptions().catchError((_) {});

  // Hive cache
  await CacheService.init();

  // Check config/app from the server. If the admin bumped lastUpdated,
  // all Hive caches are wiped here before anything else runs.
  final didUpdate = await FirebaseService().checkForUpdates();

  // Warm the active season cache before the app renders
  try {
    await FirebaseService().getActiveSeason();
  } catch (_) {}

  // If the admin triggered an update, invalidate the in-memory search index too
  if (didUpdate) SearchService().invalidate();

  // Start real-time config watcher — detects admin changes while app is open
  FirebaseService().startConfigWatcher();

  // Build search index in the background.
  // forceRefresh=true when admin bumped a timestamp so stale cache is bypassed.
  SearchService().ensureIndexLoaded(forceRefresh: didUpdate).catchError((_) {});

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Futsal Zadar',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MainPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _bottomNavIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const MatchPage(),
    const LeaguePage(),
    const NewsPage(),
    const FavoritesPage(),
  ];

  @override
  void dispose() {
    FirebaseService().disposeMatchesStream();
    FirebaseService().stopConfigWatcher();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_bottomNavIndex],
      bottomNavigationBar: BottomNavBar(
        activeIndex: _bottomNavIndex,
        onTap: (index) {
          setState(() {
            _bottomNavIndex = index;
          });
        },
      ),
    );
  }
}
