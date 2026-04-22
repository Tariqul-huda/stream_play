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
      body: Container(
        decoration: const BoxDecoration(
          gradient: ColorTheme.mainGradient, // Apply your gradient here
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
            color: Colors.white.withOpacity(0.1),
            child: BottomNavigationBar(
              backgroundColor: Colors.transparent,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: ColorTheme.neonLabelColor,
              selectedLabelStyle: const TextStyle(
                color: ColorTheme.neonLabelColor,
                shadows: [ColorTheme.neonLabelGlow],
                fontWeight: FontWeight.bold
              ),
              unselectedItemColor: Colors.grey[400],
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
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
