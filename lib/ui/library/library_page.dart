import 'package:flutter/material.dart';
import 'liked_tracks_page.dart';
import 'downloaded_page.dart';

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
    return ListView(
        children: [
    ListTile(
    leading: const Icon(Icons.favorite, color: Colors.red),
    title: const Text("Liked Tracks"),
    subtitle:
    const Text(
      "Songs you've liked",
      style:
      TextStyle(
        color: Colors.grey,
        fontSize: 13,
      ),
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
    subtitle:
    const Text("Offline music",
      style:
      TextStyle(
        color: Colors.grey,
        fontSize: 13,
      ),
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
      ],
    );
  }
}

class _AlbumsTab extends StatelessWidget {
  const _AlbumsTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text("Liked Albums (Coming Soon)"),
    );
  }
}

class _ArtistsTab extends StatelessWidget {
  const _ArtistsTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text("Liked Artists (Coming Soon)"),
    );
  }
}
