import 'package:flutter/material.dart';
import 'liked_tracks_page.dart';
import 'downloaded_page.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:rhythmax/core/library/album_library_manager.dart';
import 'package:rhythmax/core/library/artist_library_manager.dart';
import 'package:rhythmax/core/library/playlist_library_manager.dart';
import 'package:rhythmax/ui/album/album_page.dart';
import 'package:rhythmax/ui/artist/artist_page.dart';
import 'package:rhythmax/ui/playlist/playlist_page.dart';
import 'package:rhythmax/ui/app_shell_page.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Library"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Playlists"),
              Tab(text: "Albums"),
              Tab(text: "Artists"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _PlaylistsTab(),
            _AlbumsTab(),
            _ArtistsTab(),
          ],
        ),
      ),
    );
  }
}

class _PlaylistsTab extends StatelessWidget {
  const _PlaylistsTab();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box('library_playlists').listenable(),
      builder: (context, box, _) {
        final playlists = PlaylistLibraryManager.getLikedPlaylists();

        return ListView(
          children: [

            // ⭐ DEFAULT PLAYLISTS

            ListTile(
              leading: const Icon(Icons.favorite, color: Colors.red),
              title: const Text("Liked Tracks"),
              subtitle: const Text(
                "Songs you've liked",
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LikedTracksPage(),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.download),
              title: const Text("Downloaded"),
              subtitle: const Text(
                "Offline music",
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DownloadedPage(),
                  ),
                );
              },
            ),

            // ⭐ SEPARATOR
            if (playlists.isNotEmpty)
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(
                  "Saved Playlists",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

            if (playlists.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  "No saved playlists yet",
                  style: TextStyle(color: Colors.white54),
                ),
              ),

            // ⭐ DYNAMIC PLAYLISTS
            ...playlists.map((playlist) {
              return ListTile(
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 2),

                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    playlist.artworkUrl ?? '',
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Image.asset(
                      'assets/images/playlist_placeholder.jpg',
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                title: Text(
                  playlist.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                subtitle: Text(
                  playlist.description ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Poppins Medium',
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),

                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PlaylistPage(playlist: playlist),
                    ),
                  );
                },
              );
            }).toList(),
          ],
        );
      },
    );
  }
}

class _AlbumsTab extends StatelessWidget {
  const _AlbumsTab();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box('library_albums').listenable(),
      builder: (context, box, _) {
        final albums = AlbumLibraryManager.getLikedAlbums();

        if (albums.isEmpty) {
          return const Center(
            child: Text(
              'No liked albums',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        return ListView.builder(
          itemCount: albums.length,
          itemBuilder: (context, index) {
            final album = albums[index];

            return ListTile(
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 2),

              leading: _artwork(album.artworkUrl, 56),

              title: Text(
                album.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              subtitle: Text(
                album.artists.join(', '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Poppins Medium',
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),

              trailing: const Icon(Icons.more_vert, size: 18),

              onTap: () {
                AppShellPage.of(context).pushPage(
                  AlbumPage(album: album),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _ArtistsTab extends StatelessWidget {
  const _ArtistsTab();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box('library_artists').listenable(),
      builder: (context, box, _) {
        final artists = ArtistLibraryManager.getLikedArtists();

        if (artists.isEmpty) {
          return const Center(
            child: Text(
              'No liked artists',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        return ListView.builder(
          itemCount: artists.length,
          itemBuilder: (context, index) {
            final artist = artists[index];

            return ListTile(
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),

              leading: CircleAvatar(
                radius: 28,
                backgroundImage: artist.artworkUrl != null
                    ? NetworkImage(artist.artworkUrl!)
                    : const AssetImage(
                  'assets/images/artist_placeholder.jpg',
                ) as ImageProvider,
              ),

              title: Text(
                artist.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              onTap: () {
                AppShellPage.of(context).pushPage(
                  ArtistDetailsPage(artist: artist),
                );
              },
            );
          },
        );
      },
    );
  }
}

Widget _artwork(String? url, double size) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(6),
    child: FadeInImage(
      placeholder: const AssetImage('assets/images/album_placeholder.jpg'),
      image: NetworkImage(url ?? ''),
      width: size,
      height: size,
      fit: BoxFit.cover,
      imageErrorBuilder: (_, __, ___) => Image.asset(
        'assets/images/album_placeholder.jpg',
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    ),
  );
}