import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────
// Models
// ─────────────────────────────────────────────────────────────

class Song {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String duration;
  final List<Color> artColors;
  final bool isFavorite;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    required this.artColors,
    this.isFavorite = false,
  });
}

class Artist {
  final String id;
  final String name;
  final int songCount;
  final List<Color> artColors;

  const Artist({
    required this.id,
    required this.name,
    required this.songCount,
    required this.artColors,
  });
}

class Playlist {
  final String id;
  final String name;
  final int songCount;
  final String totalDuration;
  final List<Color> artColors;

  const Playlist({
    required this.id,
    required this.name,
    required this.songCount,
    required this.totalDuration,
    required this.artColors,
  });
}

// ─────────────────────────────────────────────────────────────
// Mock Data
// ─────────────────────────────────────────────────────────────

const List<Song> recentSongs = [
  Song(
    id: '1',
    title: 'Midnight Dreams',
    artist: 'Luna Echo',
    album: 'Neon Skies',
    duration: '3:45',
    artColors: [Color(0xFF6C3483), Color(0xFF1A237E)],
    isFavorite: true,
  ),
  Song(
    id: '2',
    title: 'Ocean Drive',
    artist: 'Solar Winds',
    album: 'Horizon',
    duration: '4:12',
    artColors: [Color(0xFF1A5276), Color(0xFF117A65)],
  ),
  Song(
    id: '3',
    title: 'Neon Lights',
    artist: 'CyberPunk',
    album: 'Circuit',
    duration: '3:28',
    artColors: [Color(0xFF880E4F), Color(0xFF4A148C)],
  ),
  Song(
    id: '4',
    title: 'Sunrise',
    artist: 'Morning Jazz',
    album: 'Dawn',
    duration: '5:10',
    artColors: [Color(0xFF7E5109), Color(0xFF922B21)],
  ),
  Song(
    id: '5',
    title: 'City Rain',
    artist: 'Urban Beats',
    album: 'Concrete',
    duration: '3:55',
    artColors: [Color(0xFF1B5E20), Color(0xFF006064)],
  ),
];

const List<Song> newReleases = [
  Song(
    id: '6',
    title: 'Starlight Sonata',
    artist: 'Celestial',
    album: 'Cosmos',
    duration: '4:22',
    artColors: [Color(0xFF4A148C), Color(0xFF1A237E)],
  ),
  Song(
    id: '7',
    title: 'Electric Storm',
    artist: 'Voltage',
    album: 'Thunder',
    duration: '3:58',
    artColors: [Color(0xFF0D47A1), Color(0xFF006064)],
  ),
  Song(
    id: '8',
    title: 'Tropical Breeze',
    artist: 'Island Soul',
    album: 'Paradise',
    duration: '5:01',
    artColors: [Color(0xFF1B5E20), Color(0xFF006064)],
  ),
  Song(
    id: '9',
    title: 'Midnight City',
    artist: 'Urban Glow',
    album: 'Nightfall',
    duration: '3:34',
    artColors: [Color(0xFF37474F), Color(0xFF1A237E)],
  ),
];

const List<Artist> popularArtists = [
  Artist(
    id: 'a1',
    name: 'Luna Echo',
    songCount: 24,
    artColors: [Color(0xFF6C3483), Color(0xFF4A148C)],
  ),
  Artist(
    id: 'a2',
    name: 'Solar Winds',
    songCount: 18,
    artColors: [Color(0xFF1A5276), Color(0xFF0D47A1)],
  ),
  Artist(
    id: 'a3',
    name: 'CyberPunk',
    songCount: 31,
    artColors: [Color(0xFF880E4F), Color(0xFF6A1B9A)],
  ),
  Artist(
    id: 'a4',
    name: 'Jazz Vibes',
    songCount: 15,
    artColors: [Color(0xFF7E5109), Color(0xFF4E342E)],
  ),
  Artist(
    id: 'a5',
    name: 'Voltage',
    songCount: 27,
    artColors: [Color(0xFF1B5E20), Color(0xFF006064)],
  ),
];

const List<Playlist> userPlaylists = [
  Playlist(
    id: 'p1',
    name: 'Chill Vibes',
    songCount: 24,
    totalDuration: '1h 38m',
    artColors: [Color(0xFF1A5276), Color(0xFF0D47A1)],
  ),
  Playlist(
    id: 'p2',
    name: 'Workout Mix',
    songCount: 18,
    totalDuration: '1h 02m',
    artColors: [Color(0xFF6C3483), Color(0xFF880E4F)],
  ),
  Playlist(
    id: 'p3',
    name: 'Late Night',
    songCount: 31,
    totalDuration: '2h 15m',
    artColors: [Color(0xFF1B5E20), Color(0xFF006064)],
  ),
  Playlist(
    id: 'p4',
    name: 'Road Trip',
    songCount: 45,
    totalDuration: '3h 10m',
    artColors: [Color(0xFF7E5109), Color(0xFF922B21)],
  ),
  Playlist(
    id: 'p5',
    name: 'Study Focus',
    songCount: 22,
    totalDuration: '1h 45m',
    artColors: [Color(0xFF37474F), Color(0xFF1A237E)],
  ),
  Playlist(
    id: 'p6',
    name: 'Party Hits',
    songCount: 50,
    totalDuration: '3h 30m',
    artColors: [Color(0xFF880E4F), Color(0xFF4A148C)],
  ),
];

// Currently playing song (singleton mock)
const Song nowPlayingSong = Song(
  id: '1',
  title: 'Midnight Dreams',
  artist: 'Luna Echo',
  album: 'Neon Skies',
  duration: '3:45',
  artColors: [Color(0xFF6C3483), Color(0xFF1A5276)],
  isFavorite: true,
);
