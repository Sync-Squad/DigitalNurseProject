import 'dart:async';
// import 'package:flutter/services.dart'; // COMMENTED OUT: No longer used after disabling alarm ringing
import 'package:just_audio/just_audio.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Service to manage alarm sound playback and screen wake lock
class AlarmService {
  static final AlarmService _instance = AlarmService._internal();
  factory AlarmService() => _instance;
  AlarmService._internal();

  AudioPlayer? _audioPlayer;
  bool _isPlaying = false;
  Timer? _systemSoundTimer;

  bool get isPlaying => _isPlaying;

  /// Start playing the alarm sound in a loop
  // TODO: Alarm ringing functionality temporarily disabled to fix lock screen issues
  // This was causing the app to work when screen is locked and appear on lock screen
  Future<void> startAlarm() async {
    if (_isPlaying) return;

    _isPlaying = true;

    // COMMENTED OUT: Wake lock functionality disabled
    // This was causing the app to keep the screen on when locked
    // try {
    //   // Enable wake lock to keep screen on
    //   await WakelockPlus.enable();
    //   print('🔔 Wake lock enabled');
    // } catch (e) {
    //   print('Error enabling wake lock: $e');
    // }

    // COMMENTED OUT: Audio playback functionality disabled
    // This was part of the alarm ringing feature that needs to be reworked
    // try {
    //   // Initialize audio player
    //   _audioPlayer = AudioPlayer();

    //   // Try to use custom alarm sound asset
    //   try {
    //     await _audioPlayer!.setAsset('assets/sounds/alarm.mp3');
    //     await _audioPlayer!.setLoopMode(LoopMode.one);
    //     await _audioPlayer!.setVolume(1.0);
    //     await _audioPlayer!.play();
    //     print('🔔 Alarm started with custom sound');
    //   } catch (e) {
    //     print('Custom sound not found, using system sound: $e');
    //     // Fallback to system notification sound loop
    //     await _playSystemSoundLoop();
    //   }
    // } catch (e) {
    //   print('Error starting alarm audio: $e');
    //   // Try fallback to system sound
    //   await _playSystemSoundLoop();
    // }
  }

  /// Play system notification sound in a loop
  // COMMENTED OUT: System sound loop functionality disabled
  // This was part of the alarm ringing feature that needs to be reworked
  // Future<void> _playSystemSoundLoop() async {
  //   print('🔔 Starting system sound loop');
  //   _systemSoundTimer?.cancel();
  //
  //   // Play system sound immediately
  //   await _playSystemSoundOnce();
  //
  //   // Then repeat every 2 seconds
  //   _systemSoundTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
  //     if (!_isPlaying) {
  //       timer.cancel();
  //       return;
  //     }
  //     await _playSystemSoundOnce();
  //   });
  // }

  /// Play system notification sound once
  // COMMENTED OUT: System sound playback disabled
  // This was part of the alarm ringing feature that needs to be reworked
  // Future<void> _playSystemSoundOnce() async {
  //   try {
  //     // Use HapticFeedback for vibration
  //     await HapticFeedback.heavyImpact();
  //     // Play system notification sound
  //     await SystemSound.play(SystemSoundType.alert);
  //   } catch (e) {
  //     print('Error playing system sound: $e');
  //   }
  // }

  /// Stop the alarm sound
  Future<void> stopAlarm() async {
    if (!_isPlaying) return;

    _isPlaying = false;

    try {
      // Cancel system sound timer
      _systemSoundTimer?.cancel();
      _systemSoundTimer = null;

      // Stop audio
      await _audioPlayer?.stop();
      await _audioPlayer?.dispose();
      _audioPlayer = null;

      // Disable wake lock
      await WakelockPlus.disable();

      print('🔕 Alarm stopped');
    } catch (e) {
      print('Error stopping alarm: $e');
    }
  }

  /// Snooze the alarm (stop sound, will be rescheduled by caller)
  Future<void> snoozeAlarm() async {
    await stopAlarm();
    print('😴 Alarm snoozed');
  }

  /// Dispose resources
  Future<void> dispose() async {
    await stopAlarm();
  }
}
