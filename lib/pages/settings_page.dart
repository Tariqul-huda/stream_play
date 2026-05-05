import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/audio_player_service.dart';
import '../color/color_scheme.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _pickAndPlayLocalMusic(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.audio,
      );

      if (result != null && result.files.single.path != null) {
        String path = result.files.single.path!;
        String fileName = result.files.single.name;
        
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
            title: const Text('Import Local Music', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Select an audio file from your device', style: TextStyle(color: Colors.grey)),
            onTap: () => _pickAndPlayLocalMusic(context),
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
            activeColor: ColorTheme.neonLabelColor,
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
