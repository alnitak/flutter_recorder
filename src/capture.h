#ifndef CAPTURE_H
#define CAPTURE_H

#include "common.h"
#include "enums.h"
#include "miniaudio.h"
#include "wav.h"
#include "opus_ogg_writer.h"
#include "opus_encoder_pipeline.h"

#include "filters/filters.h"
#include <string>
#include <vector>

struct CaptureDevice {
  char *name;
  unsigned int isDefault;
  unsigned int id;
};

class Capture {
public:
  Capture();
  ~Capture();

  /// stores a list of available capture devices
  /// detected by miniaudio
  std::vector<CaptureDevice> listCaptureDevices();

  /// @brief initialize the capture with a [deviceID]. A list of devices
  ///     can be acquired with [listCaptureDevices].
  ///     If [deviceID] is -1, the default will be used
  /// @param filters the filters
  /// @param deviceID the device ID chosen to be initialized
  /// @param pcmFormat the PCM format
  /// @param sampleRate the sample rate
  /// @param channels the number of channels
  /// @param androidInputPreset Android input preset. 0 leaves it unset.
  /// @return `captureNoError` if no error or else `captureInitFailed`
  CaptureErrors init(Filters *filters, int deviceID, PCMFormat pcmFormat,
                     unsigned int sampleRate, unsigned int channels,
                     int androidInputPreset);

  /// @brief Must be called when there is no more need of the capture or when
  /// closing the app
  void dispose();

  bool isInited();

  bool isDeviceStarted();

  CaptureErrors start();

  void stop();

  void startStreamingData(StreamingFormat streamingFormat);
  void stopStreamingData();

  void setSilenceDetection(bool enable);

  void setSilenceThresholdDb(float silenceThresholdDb);
  void setSilenceDuration(float silenceDuration);
  void setSecondsOfAudioToWriteBefore(float secondsOfAudioToWriteBefore);

  CaptureErrors startRecording(const char *path, RecordingFormat recordingFormat);

  void setPauseRecording(bool pause);

  void stopRecording();

  float *getWave(bool *isTheSameAsBefore);

  float getVolumeDb();

  ma_device_config deviceConfig;

  /// Wheter or not the callback is detecting silence.
  bool isDetectingSilence;

  /// The threshold for detecting silence.
  float silenceThresholdDb;

  /// The duration of silence in seconds after which the silence is considered
  /// silence.
  float silenceDuration;

  /// ms of audio to write occurred before starting recording againg after
  /// silence.
  float secondsOfAudioToWriteBefore;

  ///
  WriteAudio::Wav wav;

  /// true when the capture device is recording.
  bool isRecording;

  /// true when the capture device is paused.
  bool isRecordingPaused;

  /// true when the capture device is streaming data.
  bool isStreamingData;

  /// The selected format for recording.
  RecordingFormat recordingFormat;

  /// The selected format for streaming.
  StreamingFormat streamingFormat;

  /// Opus encoder pipeline used while streaming.
  std::unique_ptr<OpusEncoderPipeline> streamOpusPipeline;

  /// Opus Ogg writer used while recording.
  WriteAudio::OpusOggWriter opusWriter;

  /// the number of bytes per sample
  int bytesPerSample;

  Filters *mFilters;

private:
  ma_context context;
  ma_device_info *pPlaybackInfos;
  ma_uint32 playbackCount;
  ma_device_info *pCaptureInfos;
  ma_uint32 captureCount;
  ma_result result;
  ma_device device;

  /// true when the capture device is initialized.
  bool mInited;

  /// true when the capture owns an explicit miniaudio context.
  bool mUsesContext;
};

#endif // CAPTURE_H
