import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/audio_player_service.dart';
import '../services/music_api_service.dart';
import '../color/color_scheme.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _pickAndPlayLocalMusic(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.audio,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.single;
        String fileName = file.name;
        // On web, path may be a data URI (playable) or null.
        // On native, path is the real filesystem path.
        String? path = file.path;
        
        if (path == null) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cannot play: file path not available')),
            );
          }
          return;
        }
        
        await AudioPlayerService().playLocalFile(path, fileName);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Playing: $fileName')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking file: $e')),
        );
      }
    }
  }

  Future<void> _importMultipleLocalSongs(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.audio,
        allowMultiple: true,
      );

      if (result == null || result.files.isEmpty) return;

      // Show progress indicator
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Text('Importing ${result.files.length} song(s)...'),
            ],
          ),
          duration: const Duration(seconds: 10),
        ),
      );

      // Build track list from picked files
      final tracks = <Map<String, dynamic>>[];
      for (final file in result.files) {
        // On web, file.path may be a huge data URI (base64 of entire file).
        // We only need the file name for metadata storage.
        // On native platforms, file.path is the real filesystem path.
        String filePath;
        if (file.path != null && !file.path!.startsWith('data:') && !file.path!.startsWith('blob:')) {
          filePath = file.path!;
        } else {
          filePath = file.name; // fallback to just the filename
        }

        // Extract title from filename (remove extension)
        String title = file.name;
        final dotIndex = title.lastIndexOf('.');
        if (dotIndex > 0) {
          title = title.substring(0, dotIndex);
        }

        tracks.add({
          'title': title,
          'artist': 'Local',
          'filePath': filePath,
          'durationSeconds': 0,
        });
      }

      if (tracks.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No valid files selected')),
          );
        }
        return;
      }

      // Send to backend
      final musicService = MusicApiService();
      final created = await musicService.bulkCreate(tracks);

      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              created.isNotEmpty
                  ? '${created.length} song(s) imported to "Local" playlist!'
                  : 'Import failed. Check console for details.',
            ),
            backgroundColor: created.isNotEmpty ? Colors.green.shade700 : Colors.red.shade700,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error importing files: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B1B1C),
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Audio Settings',
              style: TextStyle(
                color: ColorTheme.neonLabelColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.library_music, color: Colors.white),
            title: const Text('Play Local Music', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Select an audio file to play', style: TextStyle(color: Colors.grey)),
            onTap: () => _pickAndPlayLocalMusic(context),
          ),
          ListTile(
            leading: const Icon(Icons.playlist_add, color: ColorTheme.neonLabelColor),
            title: const Text('Import Local Songs', style: TextStyle(color: Colors.white)),
            subtitle: const Text(
              'Select multiple audio files to add to your "Local" playlist',
              style: TextStyle(color: Colors.grey),
            ),
            onTap: () => _importMultipleLocalSongs(context),
          ),
          const Divider(color: Colors.white24),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'App Preferences',
              style: TextStyle(
                color: ColorTheme.neonLabelColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          SwitchListTile(
            title: const Text('Data Saver', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Sets audio quality to low', style: TextStyle(color: Colors.grey)),
            value: false,
            onChanged: (bool value) {
              // TODO: implement
            },
            activeThumbColor: ColorTheme.neonLabelColor,
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Log out', style: TextStyle(color: Colors.red)),
            onTap: () {
              // TODO: Clear session and navigate to Login
            },
          ),
        ],
      ),
    );
  }
}
