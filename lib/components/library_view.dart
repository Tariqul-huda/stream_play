import 'package:flutter/material.dart';
import '../color/color_scheme.dart';
import '../models/playlist_model.dart';
import '../models/folder_model.dart';
import '../services/playlist_service.dart';
import '../services/folder_service.dart';

class LibraryView extends StatefulWidget {
  const LibraryView({super.key});

  @override
  State<LibraryView> createState() => _LibraryViewState();
}

class _LibraryViewState extends State<LibraryView> with SingleTickerProviderStateMixin {
  final PlaylistService _playlistService = PlaylistService();
  final FolderService _folderService = FolderService();

  List<PlaylistModel> _playlists = [];
  List<FolderModel> _folders = [];
  bool _isLoading = true;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _playlistService.getPlaylists(),
        _folderService.getFolders(),
      ]);
      setState(() {
        _playlists = results[0] as List<PlaylistModel>;
        _folders = results[1] as List<FolderModel>;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _showCreatePlaylistDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('New Playlist', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Playlist name',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: ColorTheme.neonLabelColor)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(ctx);
                await _playlistService.createPlaylist(name);
                _loadData();
              }
            },
            child: const Text('Create', style: TextStyle(color: ColorTheme.neonLabelColor)),
          ),
        ],
      ),
    );
  }

  void _showCreateFolderDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('New Folder', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Folder name',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: ColorTheme.neonLabelColor)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(ctx);
                await _folderService.createFolder(name);
                _loadData();
              }
            },
            child: const Text('Create', style: TextStyle(color: ColorTheme.neonLabelColor)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 8, top: 48, bottom: 8),
            child: Row(
              children: [
                const Text(
                  'Your Library',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.white, size: 28),
                  tooltip: 'Create',
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: const Color(0xFF1E1E2C),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      builder: (ctx) => SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 8),
                            Container(
                              width: 40, height: 4,
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: ColorTheme.neonLabelColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.playlist_add, color: ColorTheme.neonLabelColor),
                              ),
                              title: const Text('New Playlist', style: TextStyle(color: Colors.white, fontSize: 16)),
                              subtitle: Text('Create a music playlist', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
                              onTap: () {
                                Navigator.pop(ctx);
                                _showCreatePlaylistDialog();
                              },
                            ),
                            ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: ColorTheme.neonLabelColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.create_new_folder_outlined, color: ColorTheme.neonLabelColor),
                              ),
                              title: const Text('New Folder', style: TextStyle(color: Colors.white, fontSize: 16)),
                              subtitle: Text('Organize your playlists', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
                              onTap: () {
                                Navigator.pop(ctx);
                                _showCreateFolderDialog();
                              },
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Tab bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(25),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: ColorTheme.neonLabelColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: ColorTheme.neonLabelColor.withValues(alpha: 0.4)),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: ColorTheme.neonLabelColor,
              unselectedLabelColor: Colors.white54,
              labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(fontSize: 14),
              tabs: const [
                Tab(text: 'Playlists'),
                Tab(text: 'Folders'),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: ColorTheme.neonLabelColor))
                : RefreshIndicator(
                    color: ColorTheme.neonLabelColor,
                    onRefresh: _loadData,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildPlaylistsTab(),
                        _buildFoldersTab(),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistsTab() {
    if (_playlists.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.library_music, size: 64, color: Colors.white.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Text('No playlists yet', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 16)),
            const SizedBox(height: 8),
            Text('Tap + to create one, or label a song!', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 13)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _playlists.length,
      itemBuilder: (context, index) {
        final playlist = _playlists[index];
        return _PlaylistTile(
          playlist: playlist,
          onDelete: () async {
            await _playlistService.deletePlaylist(playlist.id);
            _loadData();
          },
        );
      },
    );
  }

  Widget _buildFoldersTab() {
    if (_folders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_outlined, size: 64, color: Colors.white.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Text('No folders yet', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 16)),
            const SizedBox(height: 8),
            Text('Tap + to create a folder', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 13)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _folders.length,
      itemBuilder: (context, index) {
        final folder = _folders[index];
        // Find playlists that belong to this folder
        final folderPlaylists = _playlists.where((p) => folder.playlistIds.contains(p.id)).toList();

        return _FolderTile(
          folder: folder,
          playlists: folderPlaylists,
          onDelete: () async {
            await _folderService.deleteFolder(folder.id);
            _loadData();
          },
        );
      },
    );
  }
}

class _PlaylistTile extends StatelessWidget {
  final PlaylistModel playlist;
  final VoidCallback onDelete;

  const _PlaylistTile({required this.playlist, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                ColorTheme.neonLabelColor.withValues(alpha: 0.3),
                ColorTheme.neonLabelColor.withValues(alpha: 0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.playlist_play, color: ColorTheme.neonLabelColor, size: 28),
        ),
        title: Text(playlist.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
        subtitle: Text(
          '${playlist.musicIds.length} song${playlist.musicIds.length == 1 ? '' : 's'}',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13),
        ),
        trailing: IconButton(
          icon: Icon(Icons.more_vert, color: Colors.white.withValues(alpha: 0.5)),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: const Color(0xFF1E1E2C),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              builder: (ctx) => SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      title: const Text('Delete Playlist', style: TextStyle(color: Colors.redAccent)),
                      onTap: () {
                        Navigator.pop(ctx);
                        onDelete();
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FolderTile extends StatelessWidget {
  final FolderModel folder;
  final List<PlaylistModel> playlists;
  final VoidCallback onDelete;

  const _FolderTile({required this.folder, required this.playlists, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.only(left: 24, right: 16, bottom: 8),
        leading: Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF6C3483).withValues(alpha: 0.4),
                const Color(0xFF4A148C).withValues(alpha: 0.2),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.folder, color: Color(0xFFBB86FC), size: 28),
        ),
        title: Text(folder.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
        subtitle: Text(
          '${folder.playlistIds.length} playlist${folder.playlistIds.length == 1 ? '' : 's'}',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.more_vert, color: Colors.white.withValues(alpha: 0.5)),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: const Color(0xFF1E1E2C),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  builder: (ctx) => SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 8),
                        Container(
                          width: 40, height: 4,
                          decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                        ),
                        const SizedBox(height: 8),
                        ListTile(
                          leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          title: const Text('Delete Folder', style: TextStyle(color: Colors.redAccent)),
                          onTap: () {
                            Navigator.pop(ctx);
                            onDelete();
                          },
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                );
              },
            ),
            Icon(Icons.expand_more, color: Colors.white.withValues(alpha: 0.4)),
          ],
        ),
        iconColor: Colors.transparent,
        collapsedIconColor: Colors.transparent,
        children: playlists.isEmpty
            ? [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text('No playlists in this folder', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 13)),
                ),
              ]
            : playlists.map((p) => ListTile(
                dense: true,
                leading: const Icon(Icons.playlist_play, color: ColorTheme.neonLabelColor, size: 20),
                title: Text(p.name, style: const TextStyle(color: Colors.white, fontSize: 14)),
                subtitle: Text('${p.musicIds.length} songs', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12)),
              )).toList(),
      ),
    );
  }
}
