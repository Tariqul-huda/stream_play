import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/audio_player_service.dart';
import '../services/google_auth_service.dart';
import '../services/music_api_service.dart';
import '../services/settings_service.dart';
import '../services/auth_storage.dart';
import '../pages/login.dart';
import '../color/color_scheme.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final SettingsService _settingsService = SettingsService();
  final AudioPlayerService _audioService = AudioPlayerService();
  final GoogleAuthService _googleAuthService = GoogleAuthService();
  final AuthStorage _authStorage = AuthStorage();

  bool _isLoading = false;
  String _userEmail = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadData();
    _audioService.addListener(_onAudioStateChanged);
  }

  @override
  void dispose() {
    _audioService.removeListener(_onAudioStateChanged);
    super.dispose();
  }

  void _onAudioStateChanged() {
    if (mounted) {
      setState(() {}); // Re-render when sleep timer updates
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await _settingsService.loadSettings();
    final token = await _authStorage.getAccessToken();
    
    // Parse JWT locally to extract email (simplistic mock parser for demonstration)
    String email = 'user@streamplay.com';
    if (token != null) {
      try {
        final parts = token.split('.');
        if (parts.length > 1) {
          final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
          final Map<String, dynamic> json = jsonDecode(payload);
          email = json['email'] ?? json['sub'] ?? 'user@streamplay.com';
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _userEmail = email;
        _isLoading = false;
      });
    }
  }

  Future<void> _pickAndPlayLocalMusic(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.audio,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.single;
        String fileName = file.name;
        String? path = file.path;
        
        if (path == null) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cannot play: file path not available')),
            );
          }
          return;
        }
        
        await _audioService.playLocalFile(path, fileName);
        
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

      final tracks = <Map<String, dynamic>>[];
      for (final file in result.files) {
        String filePath;
        if (file.path != null && !file.path!.startsWith('data:') && !file.path!.startsWith('blob:')) {
          filePath = file.path!;
        } else {
          filePath = file.name;
        }

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

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    final messenger = ScaffoldMessenger.of(context);

    final success = await _googleAuthService.signIn();

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        final email = _googleAuthService.currentUser?.email ?? '';
        messenger.showSnackBar(
          SnackBar(
            content: Text('Successfully linked Google account: $email'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      } else {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Google sign-in was cancelled or failed.'),
          ),
        );
      }
    }
  }

  Future<void> _disconnectGoogle() async {
    setState(() => _isLoading = true);
    final messenger = ScaffoldMessenger.of(context);

    await _googleAuthService.signOut();

    if (mounted) {
      setState(() => _isLoading = false);
      messenger.showSnackBar(
        const SnackBar(content: Text('Google account disconnected.')),
      );
    }
  }

  String _formatSleepTimer(int seconds) {
    if (seconds <= 0) return 'Off';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')} remaining';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _settingsService,
      builder: (context, child) {
        final currentSettings = _settingsService.settings;
        final sleepSeconds = _audioService.sleepTimerSecondsRemaining;

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: const Color(0xFF161622),
            title: const Text('Settings & Privacy', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            iconTheme: const IconThemeData(color: Colors.white),
            elevation: 0,
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator(color: ColorTheme.neonLabelColor))
              : ListView(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  children: [
                    // Profile Header Card
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            ColorTheme.neonLabelColor.withValues(alpha: 0.15),
                            Colors.white.withValues(alpha: 0.03),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: ColorTheme.neonLabelColor.withValues(alpha: 0.15)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: ColorTheme.neonLabelColor.withValues(alpha: 0.2),
                            child: const Icon(Icons.person, size: 36, color: ColorTheme.neonLabelColor),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Active Streamer',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _userEmail,
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Google Account Integration Section
                    _buildSectionHeader('Connected Services'),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              if (currentSettings.isGoogleConnected && currentSettings.googlePhotoUrl != null)
                                CircleAvatar(
                                  radius: 14,
                                  backgroundImage: NetworkImage(currentSettings.googlePhotoUrl!),
                                  onBackgroundImageError: (_, _) {},
                                )
                              else
                                Container(
                                  width: 28, height: 28,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.g_mobiledata_rounded, color: Colors.blue, size: 20),
                                  ),
                                ),
                              const SizedBox(width: 12),
                              const Text(
                                'Google Account',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              const Spacer(),
                              if (currentSettings.isGoogleConnected)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check, color: Colors.green, size: 12),
                                      SizedBox(width: 4),
                                      Text('Connected', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                )
                              else
                                Text(
                                  'Unlinked',
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (currentSettings.isGoogleConnected) ...[
                            Text(
                              'Linked as ${currentSettings.googleName ?? ""} (${currentSettings.googleEmail ?? ""})',
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _disconnectGoogle,
                              icon: const Icon(Icons.link_off, size: 18),
                              label: const Text('Disconnect Google Account'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.withValues(alpha: 0.15),
                                foregroundColor: Colors.redAccent,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ] else ...[
                            Text(
                              'Connect your Google account to sync and access your customized YouTube playback and search history.',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12, height: 1.4),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _handleGoogleSignIn,
                              icon: const Icon(Icons.link, size: 18),
                              label: const Text('Connect Google Account'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ColorTheme.neonLabelColor.withValues(alpha: 0.15),
                                foregroundColor: ColorTheme.neonLabelColor,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Custom Theme Accents Selector
                    _buildSectionHeader('Appearance & Aesthetics'),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Theme Accent Preset',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Choose your dynamic neon highlight theme',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: ColorTheme.presets.keys.map((themeName) {
                                final color = ColorTheme.presets[themeName]!;
                                final isSelected = currentSettings.theme == themeName || 
                                    (currentSettings.theme == null && themeName == 'Cyan Neon');
                                
                                return GestureDetector(
                                  onTap: () async {
                                    currentSettings.theme = themeName;
                                    await _settingsService.saveSettings(currentSettings);
                                    setState(() {});
                                  },
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 48, height: 48,
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.2),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isSelected ? color : Colors.transparent,
                                            width: 3,
                                          ),
                                          boxShadow: isSelected
                                              ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 10)]
                                              : null,
                                        ),
                                        child: Center(
                                          child: isSelected 
                                              ? const Icon(Icons.check, color: Colors.white, size: 20)
                                              : Container(
                                                  width: 16, height: 16,
                                                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                                                ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        themeName.split(' ')[0],
                                        style: TextStyle(
                                          color: isSelected ? Colors.white : Colors.white54,
                                          fontSize: 11,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Playback Preferences
                    _buildSectionHeader('Playback Preferences'),
                    SwitchListTile(
                      title: const Text('Autoplay Next Track', style: TextStyle(color: Colors.white, fontSize: 14)),
                      subtitle: const Text('Automatically queues and plays related tracks', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      value: currentSettings.autoplayNext,
                      onChanged: (val) async {
                        currentSettings.autoplayNext = val;
                        await _settingsService.saveSettings(currentSettings);
                        setState(() {});
                      },
                      activeThumbColor: ColorTheme.neonLabelColor,
                    ),
                    
                    // Sleep Timer
                    ListTile(
                      title: const Text('Sleep Timer', style: TextStyle(color: Colors.white, fontSize: 14)),
                      subtitle: Text(
                        sleepSeconds > 0 
                            ? 'Auto-pauses in: ${_formatSleepTimer(sleepSeconds)}' 
                            : 'Set media auto-stop timer', 
                        style: TextStyle(color: sleepSeconds > 0 ? ColorTheme.neonLabelColor : Colors.grey, fontSize: 12)
                      ),
                      trailing: DropdownButton<int>(
                        value: sleepSeconds > 0 ? null : 0,
                        dropdownColor: const Color(0xFF161622),
                        underline: const SizedBox(),
                        icon: Icon(Icons.access_time_outlined, color: sleepSeconds > 0 ? ColorTheme.neonLabelColor : Colors.white54),
                        hint: Text(
                          sleepSeconds > 0 ? 'Active' : 'Off', 
                          style: TextStyle(color: sleepSeconds > 0 ? ColorTheme.neonLabelColor : Colors.white54, fontSize: 13, fontWeight: FontWeight.bold)
                        ),
                        items: const [
                          DropdownMenuItem(value: 0, child: Text('Off', style: TextStyle(color: Colors.white, fontSize: 13))),
                          DropdownMenuItem(value: 1, child: Text('1 Minute (Test)', style: TextStyle(color: Colors.white, fontSize: 13))),
                          DropdownMenuItem(value: 15, child: Text('15 Minutes', style: TextStyle(color: Colors.white, fontSize: 13))),
                          DropdownMenuItem(value: 30, child: Text('30 Minutes', style: TextStyle(color: Colors.white, fontSize: 13))),
                          DropdownMenuItem(value: 45, child: Text('45 Minutes', style: TextStyle(color: Colors.white, fontSize: 13))),
                          DropdownMenuItem(value: 60, child: Text('60 Minutes', style: TextStyle(color: Colors.white, fontSize: 13))),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            if (val == 0) {
                              _audioService.cancelSleepTimer();
                            } else {
                              _audioService.startSleepTimer(val);
                            }
                            setState(() {});
                          }
                        },
                      ),
                    ),

                    // Audio Settings
                    _buildSectionHeader('Audio & Performance'),
                    ListTile(
                      title: const Text('Audio Stream Quality', style: TextStyle(color: Colors.white, fontSize: 14)),
                      subtitle: Text('Current Quality: ${currentSettings.audioQuality}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      trailing: DropdownButton<String>(
                        value: currentSettings.audioQuality,
                        dropdownColor: const Color(0xFF161622),
                        underline: const SizedBox(),
                        icon: const Icon(Icons.tune, color: Colors.white54),
                        items: const [
                          DropdownMenuItem(value: 'Low', child: Text('Low (Data Saver)', style: TextStyle(color: Colors.white, fontSize: 13))),
                          DropdownMenuItem(value: 'Medium', child: Text('Medium', style: TextStyle(color: Colors.white, fontSize: 13))),
                          DropdownMenuItem(value: 'High', child: Text('High (Lossless)', style: TextStyle(color: Colors.white, fontSize: 13))),
                        ],
                        onChanged: (val) async {
                          if (val != null) {
                            currentSettings.audioQuality = val;
                            await _settingsService.saveSettings(currentSettings);
                            setState(() {});
                          }
                        },
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.library_music, color: Colors.white),
                      title: const Text('Play Local Music', style: TextStyle(color: Colors.white, fontSize: 14)),
                      subtitle: const Text('Select a local audio file to play', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      onTap: () => _pickAndPlayLocalMusic(context),
                    ),
                    ListTile(
                      leading: const Icon(Icons.playlist_add, color: ColorTheme.neonLabelColor),
                      title: const Text('Import Local Songs', style: TextStyle(color: Colors.white, fontSize: 14)),
                      subtitle: const Text(
                        'Select multiple audio files to add to your "Local" playlist',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      onTap: () => _importMultipleLocalSongs(context),
                    ),

                    // Clear Storage & History
                    _buildSectionHeader('Data Management'),
                    ListTile(
                      leading: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent),
                      title: const Text('Clear YouTube History', style: TextStyle(color: Colors.redAccent, fontSize: 14)),
                      subtitle: const Text('Erases all saved YouTube playback logs', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      onTap: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        await _settingsService.clearYoutubeHistory();
                        messenger.showSnackBar(
                          const SnackBar(content: Text('YouTube playback history cleared.')),
                        );
                      },
                    ),

                    // Logout
                    const Divider(color: Colors.white24, height: 32),
                    ListTile(
                      leading: const Icon(Icons.logout, color: Colors.red),
                      title: const Text('Log Out', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: const Text('Ends current session and returns to login', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      onTap: () async {
                        final navigator = Navigator.of(context);
                        await _authStorage.clear();
                        navigator.pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                          (route) => false,
                        );
                      },
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: ColorTheme.neonLabelColor,
          fontWeight: FontWeight.bold,
          fontSize: 11,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
