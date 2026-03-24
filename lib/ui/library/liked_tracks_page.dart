import 'package:flutter/material.dart';
import '../../core/library/library_manager.dart';
import 'package:rhythmax/core/models/track.dart';
import 'package:rhythmax/core/player/player_provider.dart';
import 'package:rhythmax/core/source/source_manager.dart';
import 'package:rhythmax/ui/widget/track_options_sheet.dart';
import 'package:rhythmax/ui/app_shell_page.dart';

class LikedTracksPage extends StatefulWidget {
  const LikedTracksPage({super.key});

  @override
  State<LikedTracksPage> createState() => _LikedTracksPageState();
}

class _LikedTracksPageState extends State<LikedTracksPage> {

  @override
  Widget build(BuildContext context) {

    final List<Track> tracks = LibraryManager.getLikedTracks();

    return Scaffold(
    appBar: AppBar(
    title: const Text("Liked Tracks"),
    ),
    body: ListView.builder(
    itemCount: tracks.length,
    itemBuilder: (context, index) {

    final track = tracks[index];

    return AnimatedBuilder(
      animation: Listenable.merge([
        globalPlayer,
        SourceManager.instance,
      ]),
      builder: (_, __) {

        final source = SourceManager.instance.activeSource;

        final explicitBlocked =
            track.isExplicit && !source.explicitEnabled;

        final isCurrent =
            globalPlayer.currentTrack?.id == track.id;

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 1,
          ),

          leading: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: FadeInImage(
              placeholder: const AssetImage(
                  'assets/images/music_placeholder.jpg'),
              image: NetworkImage(track.artworkUrl ?? ''),
              width: 55,
              height: 55,
              fit: BoxFit.cover,
              imageErrorBuilder: (_, __, ___) => Image.asset(
                'assets/images/music_placeholder.jpg',
                width: 55,
                height: 55,
                fit: BoxFit.cover,
              ),
            ),
          ),

          title: Text(
            track.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isCurrent
                  ? Theme.of(context).colorScheme.primary
                  : explicitBlocked
                  ? Colors.white30
                  : Colors.white,
              fontWeight:
              isCurrent ? FontWeight.w700 : FontWeight.w600,
            ),
          ),

          subtitle: Row(
            children: [
              if (track.isExplicit)
                const Padding(
                  padding: EdgeInsets.only(right: 3),
                  child: Icon(
                    Icons.explicit,
                    size: 13,
                    color: Colors.grey,
                  ),
                ),

              Expanded(
                child: Text(
                  track.artists.join(', '),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Poppins Medium',
                    color: Colors.white54,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),

          trailing: IconButton(
            icon: const Icon(Icons.more_vert, size: 18),
            onPressed: () {
              showModalBottomSheet(
                useSafeArea: true,
                useRootNavigator: true,
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (_) => TrackOptionsSheet(
                  track: track,
                  shell: AppShellPage.of(context),
                ),
              );
            },
          ),

          onTap: () {

            if (explicitBlocked) {
              _showExplicitBlockedDialog(context);
              return;
            }

            final isThisLibraryQueue =
                globalPlayer.queueSourceType == 'library' &&
                    globalPlayer.queueSourceId == 'liked_tracks';

            if (isThisLibraryQueue) {
              globalPlayer.playFromCurrentQueue(track);
              return;
            }

            globalPlayer.playTrack(
              track,
              queue: tracks,
              sourceId: 'liked_tracks',
              sourceType: 'library',
              playType: 'THE PLAYLIST',
              sourceTitle: 'Liked Tracks',
            );
          },
        );
      },
    );
        },
      ),
    );
  }
  void _showExplicitBlockedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Explicit Content'),
        content: const Text(
          'Enable explicit content in the active source settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
