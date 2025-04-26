import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';

/// Initialize audio support for the current platform.
/// This must be called before using any audio features.
Future<void> initializeAudioSupport() async {
  if (Platform.isLinux) {
    debugPrint('Initializing audio support for Linux using media_kit');
    // Initialize just_audio_media_kit for Linux
    JustAudioMediaKit.ensureInitialized();
    
    // Set the title for the audio player (appears in system volume controls)
    JustAudioMediaKit.title = 'Linux File Manager';
  }
  // The default just_audio implementation is used for other platforms
} 