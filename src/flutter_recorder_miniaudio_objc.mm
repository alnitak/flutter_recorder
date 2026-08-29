// On Apple platforms, miniaudio.h includes AVFoundation Objective-C headers,
// so the miniaudio backend must be compiled as Objective-C++.
// The build hook compiles this shim (clang treats .mm as Objective-C++)
// instead of the .cpp directly.

#include "miniaudio.cpp"

#if defined(__APPLE__)
#include <TargetConditionals.h>
#if TARGET_OS_IPHONE
#import <AVFoundation/AVFoundation.h>

extern "C" int setIosAudioSessionPreset(int preset) {
  if (preset == 0) return 0;
  @autoreleasepool {
    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSError *error = nil;

    AVAudioSessionCategoryOptions options =
        AVAudioSessionCategoryOptionDefaultToSpeaker |
        AVAudioSessionCategoryOptionAllowBluetooth;

    if (![session setCategory:AVAudioSessionCategoryPlayAndRecord
                  withOptions:options
                        error:&error]) {
      return -1;
    }

    AVAudioSessionMode mode = AVAudioSessionModeDefault;
    switch (preset) {
    case 1: // generic
      mode = AVAudioSessionModeDefault;
      break;
    case 2: // voiceCommunication (voiceChat -> hardware AEC + AGC + voice EQ)
      mode = AVAudioSessionModeVoiceChat;
      break;
    case 3: // videoChat
      mode = AVAudioSessionModeVideoChat;
      break;
    case 4: // speechRecognition (spokenAudio)
      mode = AVAudioSessionModeSpokenAudio;
      break;
    case 5: // unprocessed (measurement -> disables AGC/filters for raw audio)
      mode = AVAudioSessionModeMeasurement;
      break;
    default:
      return -1;
    }

    if (![session setMode:mode error:&error]) {
      return -1;
    }

    if (![session setActive:YES error:&error]) {
      return -1;
    }
  }
  return 0;
}
#else
extern "C" int setIosAudioSessionPreset(int preset) {
  return 0;
}
#endif
#endif
