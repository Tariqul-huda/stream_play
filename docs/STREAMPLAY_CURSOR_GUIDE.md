# StreamPlay App Guide for Cursor

This document is a practical map of the existing Flutter application so an AI assistant or engineer can inspect bugs quickly without changing the architecture.

## 1. App Overview

StreamPlay is an existing Flutter music player app with:

- Login and signup flow
- Home dashboard
- YouTube search and audio playback
- Local file playback
- Playlist and folder management
- Mini player that persists across the app shell
- Settings page for Google account linking and playback options
- SharedPreferences-based settings/history storage
- Hive-based local storage for notes, favorites, and playback state

The app is not a new scaffold. It is an existing codebase that should be extended safely.

## 2. Main Entry Points

- App bootstrap: [lib/main.dart](../lib/main.dart)
- Shell/navigation: [lib/pages/home_page.dart](../lib/pages/home_page.dart)
- Dashboard home content: [lib/components/home_view.dart](../lib/components/home_view.dart)
- Now playing screen: [lib/pages/player_page.dart](../lib/pages/player_page.dart)
- Search screen: [lib/pages/search_page.dart](../lib/pages/search_page.dart)
- Settings screen: [lib/pages/settings_page.dart](../lib/pages/settings_page.dart)
- Mini player: [lib/components/mini_player.dart](../lib/components/mini_player.dart)

## 3. Project Structure

### UI / Screens

- [lib/pages/login.dart](../lib/pages/login.dart)
- [lib/pages/signup.dart](../lib/pages/signup.dart)
- [lib/pages/forgot_password.dart](../lib/pages/forgot_password.dart)
- [lib/pages/search_page.dart](../lib/pages/search_page.dart)
- [lib/pages/player_page.dart](../lib/pages/player_page.dart)
- [lib/pages/settings_page.dart](../lib/pages/settings_page.dart)
- [lib/pages/home_page.dart](../lib/pages/home_page.dart)

### Shared Components

- [lib/components/home_view.dart](../lib/components/home_view.dart)
- [lib/components/mini_player.dart](../lib/components/mini_player.dart)
- [lib/components/library_view.dart](../lib/components/library_view.dart)
- [lib/components/horizontal_scroll_section.dart](../lib/components/horizontal_scroll_section.dart)
- [lib/components/recent_grid_card.dart](../lib/components/recent_grid_card.dart)

### Services

- [lib/services/audio_player_service.dart](../lib/services/audio_player_service.dart)
- [lib/services/google_auth_service.dart](../lib/services/google_auth_service.dart)
- [lib/services/settings_service.dart](../lib/services/settings_service.dart)
- [lib/services/music_local_storage.dart](../lib/services/music_local_storage.dart)
- [lib/services/auth_api.dart](../lib/services/auth_api.dart)
- [lib/services/auth_storage.dart](../lib/services/auth_storage.dart)
- [lib/services/playlist_service.dart](../lib/services/playlist_service.dart)
- [lib/services/folder_service.dart](../lib/services/folder_service.dart)

### Models

- [lib/models/music_data.dart](../lib/models/music_data.dart)
- [lib/models/playlist_model.dart](../lib/models/playlist_model.dart)
- [lib/models/playlist_song.dart](../lib/models/playlist_song.dart)
- [lib/models/folder_model.dart](../lib/models/folder_model.dart)

## 4. Architecture Summary

### State Management

The app uses service singletons plus `ChangeNotifier`/`ListenableBuilder` patterns.

- `AudioPlayerService` is the central playback singleton.
- `SettingsService` stores user settings and YouTube history.
- `GoogleAuthService` manages Google sign-in and YouTube API access.
- `AuthStorage` stores the API auth token in SharedPreferences.

There is no Redux, Bloc, Riverpod, or Provider-based global state layer in the current app.

### Navigation

Navigation is imperative with `Navigator.push` and `Navigator.pushReplacement`.

- `LoginPage` routes to `HomePage`
- `HomePage` hosts a 3-tab shell: Home, Search, Library
- `MiniPlayer` opens `PlayerPage`
- Settings and search open their own screens through direct navigation

## 5. Startup Flow

Current startup path:

1. `main.dart` loads `.env`
2. Local storage is initialized
3. Background audio is initialized on non-web platforms
4. `AudioPlayerService().init()` attaches playback listeners
5. `GoogleAuthService().trySilentSignIn()` attempts to restore the previous Google session
6. `MaterialApp` launches with `HomePage`

Important file: [lib/main.dart](../lib/main.dart)

## 6. Playback Flow

### Audio Engine

`AudioPlayerService` uses `just_audio` and `just_audio_background`.

Supported actions:

- Play local file
- Play URL stream
- Pause / resume
- Seek
- Previous / next in queue
- Loop
- Sleep timer

Important file: [lib/services/audio_player_service.dart](../lib/services/audio_player_service.dart)

### YouTube Audio Playback

The search screen resolves YouTube content into an audio-only stream by:

1. Searching YouTube or fallback Piped APIs
2. Extracting stream URLs with `youtube_explode_dart`
3. Playing the extracted audio URL via `AudioPlayerService.playUrl`

Important file: [lib/pages/search_page.dart](../lib/pages/search_page.dart)

### Mini Player

The mini player listens to the audio service and is intended to stay available across the shell.

Important file: [lib/components/mini_player.dart](../lib/components/mini_player.dart)

## 7. Persistence

### Existing Persistence

- `SharedPreferences` for settings cache and YouTube history
- `AuthStorage` for API access token

### Added Local Storage

- Hive stores notes per track
- Hive stores playback position per track
- Hive stores recent tracks
- Hive stores favorite track IDs and snapshots

Important file: [lib/services/music_local_storage.dart](../lib/services/music_local_storage.dart)

### Current Data Sources

- YouTube playback history: `SettingsService.settings.youtubeHistory`
- Playback notes: `MusicLocalStorage`
- Playback position: `MusicLocalStorage`
- Favorites: `MusicLocalStorage`

## 8. Google Account Connection Flow

Google auth is handled in [lib/services/google_auth_service.dart](../lib/services/google_auth_service.dart).

### Expected Flow

1. User taps Google sign-in in Settings
2. `GoogleSignIn.signIn()` opens OAuth
3. On success, the service caches the account in `_currentUser`
4. `SettingsService` is updated with:
   - `isGoogleConnected`
   - email
   - display name
   - photo URL
5. `search_page.dart` uses the signed-in account to fetch liked videos and search YouTube

### Why Google Connection Can Fail

Likely failure points to inspect first:

- Missing or wrong `GOOGLE_CLIENT_ID` in `.env`
- OAuth client not configured for the web origin or Android/iOS package ID
- `google_sign_in` setup mismatch for the platform being tested
- YouTube API access token is missing/expired
- `trySilentSignIn()` succeeds or fails but settings/cache state does not match the UI expectation
- `SettingsService.loadSettings()` and Google auth state may briefly disagree on startup

### Concrete files for Google auth debugging

- [lib/services/google_auth_service.dart](../lib/services/google_auth_service.dart)
- [lib/services/settings_service.dart](../lib/services/settings_service.dart)
- [lib/pages/settings_page.dart](../lib/pages/settings_page.dart)
- [lib/pages/search_page.dart](../lib/pages/search_page.dart)
- [lib/main.dart](../lib/main.dart)

## 9. Bug Hotspots

These are the most likely files to inspect when something is broken.

### Google account connection not working

Check:

- [lib/services/google_auth_service.dart](../lib/services/google_auth_service.dart)
- `.env` for `GOOGLE_CLIENT_ID`
- Google Cloud Console OAuth settings
- Settings page sign-in handler in [lib/pages/settings_page.dart](../lib/pages/settings_page.dart)

### Playback starts but state is not restored

Check:

- [lib/services/audio_player_service.dart](../lib/services/audio_player_service.dart)
- [lib/services/music_local_storage.dart](../lib/services/music_local_storage.dart)
- [lib/pages/player_page.dart](../lib/pages/player_page.dart)

### History does not update

Check:

- [lib/services/settings_service.dart](../lib/services/settings_service.dart)
- [lib/pages/search_page.dart](../lib/pages/search_page.dart)

### Mini player not showing

Check:

- [lib/components/mini_player.dart](../lib/components/mini_player.dart)
- `AudioPlayerService.currentTrackTitle`
- Whether the active track has started successfully

### Queue navigation issues

Check:

- `setQueue`, `playNext`, `playPrevious` in [lib/services/audio_player_service.dart](../lib/services/audio_player_service.dart)

## 10. Known Behavior Notes

- The app is designed to be backward compatible with the existing UI and shell.
- Search is intentionally fallback-driven: Google API first, then Piped instances.
- Playback history is still stored in `SettingsService` so existing pages keep working.
- Notes and favorites are stored locally so they survive app restarts.
- Background audio support is platform-dependent; web can play audio, but mobile lock-screen behavior depends on native setup.

## 11. Useful Debug Targets for Cursor

If you want Cursor to find the bug, give it one of these tasks:

1. Inspect `GoogleAuthService.signIn()` and `trySilentSignIn()` and identify why `SettingsPage` says Google is not connected even after a successful sign-in.
2. Inspect `main.dart`, `settings_page.dart`, and `.env` to verify whether Google OAuth is configured correctly for the target platform.
3. Inspect `AudioPlayerService` and `PlayerPage` to verify playback position is saved and restored per track.
4. Inspect `search_page.dart` to verify liked videos and YouTube playback history are using the same account state as settings.

## 12. Safety Rules For Future Changes

- Reuse `AudioPlayerService` instead of introducing a second playback engine.
- Reuse `SettingsService` history if the existing UI already consumes it.
- Reuse `MusicLocalStorage` for notes, favorites, and saved playback state.
- Do not replace the `HomePage` shell unless there is a hard bug requiring it.
- Keep new state isolated to the current service boundary when possible.

## 13. Backend Overview

The Flutter app talks to a separate ASP.NET Core backend under [backend/StreamPlay.Api](../backend/StreamPlay.Api).

### Backend entry points

- Startup: [backend/StreamPlay.Api/Program.cs](../backend/StreamPlay.Api/Program.cs)
- Auth controller: [backend/StreamPlay.Api/Controllers/AuthController.cs](../backend/StreamPlay.Api/Controllers/AuthController.cs)
- Settings controller: [backend/StreamPlay.Api/Controllers/SettingsController.cs](../backend/StreamPlay.Api/Controllers/SettingsController.cs)
- Music controller: [backend/StreamPlay.Api/Controllers/MusicController.cs](../backend/StreamPlay.Api/Controllers/MusicController.cs)
- Playlists controller: [backend/StreamPlay.Api/Controllers/PlaylistsController.cs](../backend/StreamPlay.Api/Controllers/PlaylistsController.cs)
- Folders controller: [backend/StreamPlay.Api/Controllers/FoldersController.cs](../backend/StreamPlay.Api/Controllers/FoldersController.cs)
- Scan controller: [backend/StreamPlay.Api/Controllers/ScanController.cs](../backend/StreamPlay.Api/Controllers/ScanController.cs)

### Backend architecture

- ASP.NET Core Web API
- MongoDB-backed repositories and services
- JWT authentication
- CORS enabled for Flutter development
- Swagger enabled in development

### Backend startup behavior

- Reads MongoDB and JWT settings from configuration
- Registers repositories and services with DI
- Ensures Mongo indexes at startup if the database is available
- Exposes `/` and `/health` for quick availability checks

## 14. Backend API Map

These are the main routes the Flutter app depends on:

- `POST /api/auth/login`
- `POST /api/auth/register`
- `POST /api/auth/send-otp`
- `POST /api/auth/reset-password`
- `GET /api/settings`
- `POST /api/settings`
- `GET /api/music`
- `POST /api/music`
- `POST /api/music/bulk`
- `GET /api/music/search`
- `GET /api/music/by-path`
- `PUT /api/music/{id}/label`
- `DELETE /api/music/{id}`
- `GET /api/playlists`
- `POST /api/playlists`
- `POST /api/playlists/{id}/add`
- `POST /api/playlists/{id}/remove`
- `DELETE /api/playlists/{id}`
- `GET /api/folders`
- `POST /api/folders`
- `POST /api/folders/{id}/add-playlist`
- `POST /api/folders/{id}/remove-playlist`
- `DELETE /api/folders/{id}`
- `POST /api/scan-folder`

### Flutter dependencies on the backend

- Login and token storage: [lib/services/auth_api.dart](../lib/services/auth_api.dart), [lib/services/auth_storage.dart](../lib/services/auth_storage.dart)
- Settings sync: [lib/services/settings_service.dart](../lib/services/settings_service.dart)
- Library data: [lib/services/playlist_service.dart](../lib/services/playlist_service.dart), [lib/services/folder_service.dart](../lib/services/folder_service.dart)
- Local file import: [lib/pages/settings_page.dart](../lib/pages/settings_page.dart)

## 15. Current Problems To Debug First

This is the practical bug list for Cursor or any engineer.

### 1. Google account connection looks broken

Most likely cause chain:

- `GoogleAuthService.signIn()` depends on `GOOGLE_CLIENT_ID` from `.env`
- `google_sign_in` also needs the OAuth client configured correctly in Google Cloud Console for the target platform
- `main.dart` calls `GoogleAuthService().trySilentSignIn()` without awaiting settings sync, so the UI can briefly show stale state
- `SettingsService.loadSettings()` loads saved backend settings and can overwrite or lag behind the live Google sign-in state

What to inspect first:

- [lib/services/google_auth_service.dart](../lib/services/google_auth_service.dart)
- [lib/pages/settings_page.dart](../lib/pages/settings_page.dart)
- [lib/services/settings_service.dart](../lib/services/settings_service.dart)
- `.env`

### 2. Background playback is only partially wired

The audio layer uses `just_audio_background`, but mobile lock-screen/media notification behavior still depends on platform setup outside Dart.

What to inspect:

- [lib/main.dart](../lib/main.dart)
- [lib/services/audio_player_service.dart](../lib/services/audio_player_service.dart)
- Android/iOS native configuration

### 3. Notes and last-position persistence depend on the active track ID

If playback is started without a stable ID, saved notes and resume position can become less reliable.

What to inspect:

- [lib/services/audio_player_service.dart](../lib/services/audio_player_service.dart)
- [lib/services/music_local_storage.dart](../lib/services/music_local_storage.dart)
- [lib/pages/player_page.dart](../lib/pages/player_page.dart)
- [lib/pages/search_page.dart](../lib/pages/search_page.dart)

### 4. Playback history is split between settings cache and local Hive storage

This is intentional, but it means debugging should check both sources.

What to inspect:

- YouTube playback history in [lib/services/settings_service.dart](../lib/services/settings_service.dart)
- Recent items and favorites in [lib/services/music_local_storage.dart](../lib/services/music_local_storage.dart)

### 5. Mini player can disappear when no active track is set

This is expected, but if it disappears unexpectedly, check whether playback ever reached a valid state.

What to inspect:

- [lib/components/mini_player.dart](../lib/components/mini_player.dart)
- [lib/services/audio_player_service.dart](../lib/services/audio_player_service.dart)

## 16. Cursor Debug Plan

If you want Cursor to find the bug quickly, give it one of these tasks:

1. Trace the Google sign-in flow from `SettingsPage` to `GoogleAuthService` and explain why connection status may not persist or may appear false after successful login.
2. Trace playback from YouTube search to `AudioPlayerService` and verify that track IDs are stable enough for notes, last position, and favorites.
3. Trace the settings/history sync path between `SettingsService`, `GoogleAuthService`, and `SearchPage` and identify any race condition.
4. Trace the backend auth flow in `AuthController`, `SettingsController`, and the Flutter `AuthApi` client to verify token handling.

## 17. Short Troubleshooting Checklist

- Check `.env` for `GOOGLE_CLIENT_ID` and `API_BASE_URL`
- Check Google Cloud Console OAuth client setup
- Check whether `SettingsService.loadSettings()` is returning stale backend data
- Check whether `trySilentSignIn()` is completing after the settings UI renders
- Check whether the backend token is valid and stored in `AuthStorage`
- Check whether playback track IDs are stable for the same video or file
