import 'package:flutter/material.dart';
import 'recent_grid_card.dart';
import 'horizontal_scroll_section.dart';
import '../pages/settings_page.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 40.0, bottom: 20.0),
            child: Row(
              children: [
                const Text(
                  "Good afternoon",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.notifications_none, color: Colors.white),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.history, color: Colors.white),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 8.0,
              crossAxisSpacing: 8.0,
              childAspectRatio: 3,
            ),
            delegate: SliverChildListDelegate(
              const [
                RecentGridCard(title: "Liked Songs"),
                RecentGridCard(title: "Discover Weekly"),
                RecentGridCard(title: "Daily Mix 1"),
                RecentGridCard(title: "Release Radar"),
                RecentGridCard(title: "Top Hits"),
                RecentGridCard(title: "Lo-Fi Beats"),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: 32),
        ),
        SliverToBoxAdapter(
          child: HorizontalScrollSection(
            title: "Jump back in",
            items: const [
              "Chill Vibes",
              "Pop Right Now",
              "Rock Classics",
              "Acoustic Hits",
              "Workout Motivation",
            ],
          ),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: 32),
        ),
        SliverToBoxAdapter(
          child: HorizontalScrollSection(
            title: "Recently played",
            items: const [
              "Ed Sheeran",
              "Taylor Swift",
              "Imagine Dragons",
              "Coldplay",
              "Billie Eilish",
            ],
          ),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: 100), // padding for mini player
        ),
      ],
    );
  }
}
