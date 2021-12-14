import 'package:bebba/state_manager/state_manager.dart';
import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class Youtube extends StatefulWidget {
  final Map<String, dynamic> meta;

  Youtube({required this.meta});

  @override
  _Youtube createState() => _Youtube();
}

class _Youtube extends State<Youtube> {

  final stateManager = StateManager();

  @override
  void initState() {
    stateManager.setCurrentState(States.YOUTUBE);
    super.initState();
  }

  final YoutubePlayerController _controller = YoutubePlayerController(
    initialVideoId: '',
    params: const YoutubePlayerParams(
      playlist: [], // Defining custom playlist
      startAt: Duration(seconds: 30),
      showControls: false,
      showFullscreenButton: true,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Youtube'),
        backgroundColor: Colors.cyan[900],
      ),
      body: YoutubePlayerControllerProvider(
        controller: _controller,
        child: const YoutubePlayerIFrame(
          aspectRatio: 16 / 9,
        ),
      ),
    );
  }
}
