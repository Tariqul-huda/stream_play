import 'package:flutter/material.dart';
import 'dart:ui';
import '../color/color_scheme.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    Center(child: Text("Home Page")),
    Center(child: Text("Search")),
    Center(child: Text("Your Library")),
    Center(child: Text("Create Playlist")),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      drawer: Drawer(
        backgroundColor: const Color(0xFF1B1B1C),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                gradient: ColorTheme.mainGradient,
              ),
              child: CircleAvatar(
                radius: 40,
                // backgroundImage: ,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person, color: ColorTheme.neonLabelColor),
              title: const Text('View Profile', style: TextStyle(color: Colors.white)),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.account_circle, color: ColorTheme.neonLabelColor),
              title: const Text('Add Account', style: TextStyle(color: Colors.white)),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: ColorTheme.neonLabelColor),
              title: const Text('Settings', style: TextStyle(color: Colors.white)),
              onTap: () {},
            ),

          ],
        ),
      ),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: const BoxDecoration(
            gradient: ColorTheme.mainGradient,
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Builder(
              builder: (context) => IconButton(
                icon: const CircleAvatar(
                  radius: 18,
                  backgroundImage: AssetImage('assets/profile.jpg'),
                ),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: ColorTheme.mainGradient,
        ),
        child: _pages[_selectedIndex],
      ),
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: Colors.white.withValues(alpha: 0.1),
            child: BottomNavigationBar(
              backgroundColor: Colors.transparent,
              type: BottomNavigationBarType.fixed,
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              selectedItemColor: ColorTheme.neonLabelColor,
              unselectedItemColor: Colors.grey[400],
              selectedLabelStyle: const TextStyle(
                color: ColorTheme.neonLabelColor,
                shadows: [ColorTheme.neonLabelGlow],
                fontWeight: FontWeight.bold,
              ),
              selectedIconTheme: const IconThemeData(
                color: ColorTheme.neonLabelColor,
                shadows: [ColorTheme.neonLabelGlow],
              ),
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
                BottomNavigationBarItem(icon: Icon(Icons.search), label: "Search"),
                BottomNavigationBarItem(icon: Icon(Icons.library_books), label: "Library"),
                BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: "Create"),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
