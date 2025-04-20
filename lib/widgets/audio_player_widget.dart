import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/file_item.dart';

class AudioPlayerWidget extends StatefulWidget {
  final FileItem audioFile;
  final bool darkMode;
  final bool compact;
  
  const AudioPlayerWidget({
    super.key,
    required this.audioFile,
    this.darkMode = false,
    this.compact = false,
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  double _progress = 0.0;
  String _currentTime = '0:00';
  String _totalTime = '0:00';
  
  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
  }
  
  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
  
  Future<void> _initAudioPlayer() async {
    debugPrint('AudioPlayerWidget: Initializing audio player for ${widget.audioFile.path}');
    
    // Listen to player state changes
    _audioPlayer.playerStateStream.listen((state) {
      debugPrint('AudioPlayerWidget: Player state changed: ${state.playing ? "playing" : "paused"}');
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
        });
      }
    });

    // Listen to duration changes
    _audioPlayer.durationStream.listen((newDuration) {
      debugPrint('AudioPlayerWidget: Duration updated: ${newDuration?.inSeconds ?? 0} seconds');
      if (newDuration != null && mounted) {
        setState(() {
          _totalTime = _formatDuration(newDuration);
        });
      }
    });

    // Listen to position changes
    _audioPlayer.positionStream.listen((newPosition) {
      if (mounted) {
        setState(() {
          _progress = _audioPlayer.duration != null ? 
            newPosition.inSeconds.toDouble() / _audioPlayer.duration!.inSeconds.toDouble() : 0.0;
          _currentTime = _formatDuration(newPosition);
        });
      }
    });

    try {
      debugPrint('AudioPlayerWidget: Setting file path: ${widget.audioFile.path}');
      await _audioPlayer.setFilePath(widget.audioFile.path);
      debugPrint('AudioPlayerWidget: File loaded successfully');
    } catch (e) {
      debugPrint('AudioPlayerWidget: Error loading audio file: $e');
    }
  }
  
  void _togglePlayPause() {
    if (_isPlaying) {
      _audioPlayer.pause();
    } else {
      _audioPlayer.play();
    }
  }
  
  void _seekTo(double value) {
    final duration = _audioPlayer.duration;
    if (duration != null) {
      final position = duration * value;
      _audioPlayer.seek(position);
    }
  }
  
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
  
  @override
  Widget build(BuildContext context) {
    final textColor = widget.darkMode ? Colors.white : Colors.black87;
    final secondaryColor = widget.darkMode ? Colors.grey[400] : Colors.grey[600];
    final progressBackgroundColor = widget.darkMode ? Colors.grey[800] : Colors.grey[300];
    final progressColor = widget.darkMode ? Colors.blue[300] : Colors.blue;
    final containerColor = widget.darkMode ? Colors.grey[900] : Colors.grey[100];
    
    if (widget.compact) {
      return _buildCompactPlayer(textColor, secondaryColor, progressBackgroundColor, progressColor);
    }
    
    return Container(
      width: 320,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (!widget.darkMode)
            BoxShadow(
              color: Colors.black.withAlpha(26),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Album art placeholder
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              color: widget.darkMode ? Colors.black : Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.audio_file,
              size: 80,
              color: widget.darkMode ? Colors.blue[300] : Colors.blue[400],
            ),
          ),
          const SizedBox(height: 24),
          
          // Title
          Text(
            widget.audioFile.name,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          
          // Artist/album (placeholder)
          Text(
            'Unknown Artist',
            style: TextStyle(
              fontSize: 14,
              color: secondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          
          // Playback controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.skip_previous),
                color: textColor,
                iconSize: 36,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Previous track')),
                  );
                },
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled),
                color: textColor,
                iconSize: 48,
                onPressed: _togglePlayPause,
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.skip_next),
                color: textColor,
                iconSize: 36,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Next track')),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Progress bar
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              activeTrackColor: progressColor,
              inactiveTrackColor: progressBackgroundColor,
              thumbColor: progressColor,
              overlayColor: progressColor?.withAlpha(51),
            ),
            child: Slider(
              value: _progress,
              min: 0.0,
              max: 1.0,
              onChanged: _seekTo,
            ),
          ),
          
          // Time indicators
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_currentTime, style: TextStyle(color: secondaryColor, fontSize: 12)),
                Text(_totalTime, style: TextStyle(color: secondaryColor, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCompactPlayer(Color textColor, Color? secondaryColor, Color? progressBackgroundColor, Color? progressColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.darkMode ? Colors.grey[850] : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title and controls in a row
          Row(
            children: [
              Icon(
                Icons.audio_file,
                size: 32,
                color: widget.darkMode ? Colors.blue[300] : Colors.blue[400],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.audioFile.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Unknown Artist',
                      style: TextStyle(
                        fontSize: 12,
                        color: secondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(_isPlaying ? Icons.pause_circle_outlined : Icons.play_circle_outlined),
                color: textColor,
                iconSize: 32,
                onPressed: _togglePlayPause,
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Progress bar
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              activeTrackColor: progressColor,
              inactiveTrackColor: progressBackgroundColor,
              thumbColor: progressColor,
              overlayColor: progressColor?.withAlpha(51),
            ),
            child: Slider(
              value: _progress,
              min: 0.0,
              max: 1.0,
              onChanged: _seekTo,
            ),
          ),
          
          // Time indicators
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_currentTime, style: TextStyle(color: secondaryColor, fontSize: 10)),
                Text(_totalTime, style: TextStyle(color: secondaryColor, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 