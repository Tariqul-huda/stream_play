import 'package:flutter/material.dart';
import '../color/color_scheme.dart';
import '../components/home_view.dart';
import '../components/library_view.dart';
import '../components/mini_player.dart';
import '../pages/settings_page.dart';
import '../pages/search_page.dart';
import '../services/settings_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final SettingsService _settingsService = SettingsService();

  final List<Widget> _pages = [
    const HomeView(),
    const SearchPage(),
    const LibraryView(),
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _settingsService.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    _settingsService.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    if (mounted) {
      setState(() {}); // Re-render when theme or settings change
    }
  }

  Future<void> _loadSettings() async {
    await _settingsService.loadSettings();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.black, // Dark background base
      drawer: Drawer(
        backgroundColor: const Color(0xFF1B1B1C),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: ColorTheme.mainGradient,
              ),
              child: const CircleAvatar(
                radius: 40,
                backgroundColor: Colors.grey,
                child: Icon(Icons.person, size: 40, color: Colors.white),
              ),
            ),
            ListTile(
              leading: Icon(Icons.person, color: ColorTheme.activeNeonColor),
              title: const Text('View Profile', style: TextStyle(color: Colors.white)),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(Icons.settings, color: ColorTheme.activeNeonColor),
              title: const Text('Settings & Privacy', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context); // close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              },
            ),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: ColorTheme.mainGradient,
        ),
        child: Stack(
          children: [
            // Main content
            _pages[_selectedIndex],
            
            // Mini Player positioned above Bottom Nav
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0, // Bottom nav will overlap or we can add margin
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 60.0), // Approximate height of BottomNav
                  child: MiniPlayer(),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withValues(alpha: 0.0),
                Colors.black.withValues(alpha: 0.8),
                Colors.black,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: BottomNavigationBar(
            backgroundColor: Colors.transparent,
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.grey,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            unselectedLabelStyle: const TextStyle(fontSize: 11),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Home"),
              BottomNavigationBarItem(icon: Icon(Icons.search), label: "Search"),
              BottomNavigationBarItem(icon: Icon(Icons.library_music), label: "Your Library"),
            ],
          ),
        ),
      ),
    );
  }
}
