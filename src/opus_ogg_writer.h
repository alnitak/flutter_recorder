#ifndef OPUS_OGG_WRITER_H
#define OPUS_OGG_WRITER_H

#include "enums.h"
#include "miniaudio.h"
#include "opus_encoder_pipeline.h"

#include <ogg/ogg.h>
#include <string>
#include <vector>

namespace WriteAudio {

/// Writes Opus encoded audio into an Ogg Opus file.
class OpusOggWriter {
public:
  OpusOggWriter();
  ~OpusOggWriter();

  CaptureErrors init(const char *path, ma_device_config deviceConfig);
  CaptureErrors write(const void *pFramesIn, ma_uint64 frameCount);
  void close();

  bool isRecording() const;

private:
  void writeHeaderPages();
  void writePacket(const unsigned char *packet, int packetSize);
  void writeOggPage(const ogg_page *page);
  void flushPages();

  bool mIsRecording;
  ma_device_config mDeviceConfig;
  OpusEncoderPipeline mPipeline;
  ogg_stream_state mOggStream;
  ogg_int64_t mGranulePos;
  long mPacketNo;

#ifndef __EMSCRIPTEN__
  FILE *mFile;
#else
  std::string mFileName;
  std::vector<unsigned char> mData;
#endif
};

} // namespace WriteAudio

#endif // OPUS_OGG_WRITER_H
