#include "opus_ogg_writer.h"

#include <cstring>
#include <time.h>

#ifdef __EMSCRIPTEN__
#include <emscripten/emscripten.h>
#endif

namespace WriteAudio {

OpusOggWriter::OpusOggWriter()
    : mIsRecording(false), mGranulePos(0), mPacketNo(0)
#ifndef __EMSCRIPTEN__
      ,
      mFile(nullptr)
#endif
{
}

OpusOggWriter::~OpusOggWriter() { close(); }

CaptureErrors OpusOggWriter::init(const char *path,
                                    ma_device_config deviceConfig) {
  close();

  mDeviceConfig = deviceConfig;
  mIsRecording = true;

#ifndef __EMSCRIPTEN__
  mFile = fopen(path, "wb");
  if (mFile == nullptr) {
    mIsRecording = false;
    return failedToInitializeRecording;
  }
#else
  mFileName = path != nullptr ? path : "output.opus";
  mData.clear();
#endif

  CaptureErrors pipelineError = mPipeline.init(
      deviceConfig.capture.format, deviceConfig.capture.channels,
      deviceConfig.sampleRate);
  if (pipelineError != captureNoError) {
    mIsRecording = false;
    return pipelineError;
  }

  mPipeline.onPacket = [this](const unsigned char *packet, int packetSize) {
    writePacket(packet, packetSize);
  };

  ogg_stream_init(&mOggStream, static_cast<int>(time(nullptr)));
  writeHeaderPages();
  flushPages();

  return captureNoError;
}

void OpusOggWriter::writeHeaderPages() {
  // OpusHead packet
  unsigned char head[19];
  std::memcpy(head, "OpusHead", 8);
  head[8] = 1; // version
  head[9] = static_cast<unsigned char>(mDeviceConfig.capture.channels);
  const int preSkip = 3840; // 80 ms at 48 kHz
  head[10] = static_cast<unsigned char>(preSkip & 0xFF);
  head[11] = static_cast<unsigned char>((preSkip >> 8) & 0xFF);
  const ma_uint32 originalRate = mDeviceConfig.sampleRate;
  head[12] = static_cast<unsigned char>(originalRate & 0xFF);
  head[13] = static_cast<unsigned char>((originalRate >> 8) & 0xFF);
  head[14] = static_cast<unsigned char>((originalRate >> 16) & 0xFF);
  head[15] = static_cast<unsigned char>((originalRate >> 24) & 0xFF);
  head[16] = 0; // output gain low
  head[17] = 0; // output gain high
  head[18] = 0; // channel mapping family

  ogg_packet headPacket;
  headPacket.packet = head;
  headPacket.bytes = sizeof(head);
  headPacket.b_o_s = 1;
  headPacket.e_o_s = 0;
  headPacket.granulepos = 0;
  headPacket.packetno = mPacketNo++;
  ogg_stream_packetin(&mOggStream, &headPacket);

  // OpusTags packet
  const char *vendor = "flutter_recorder";
  const int vendorLen = static_cast<int>(std::strlen(vendor));
  std::vector<unsigned char> tags(8 + 4 + vendorLen + 4);
  std::memcpy(tags.data(), "OpusTags", 8);
  tags[8] = static_cast<unsigned char>(vendorLen & 0xFF);
  tags[9] = static_cast<unsigned char>((vendorLen >> 8) & 0xFF);
  tags[10] = static_cast<unsigned char>((vendorLen >> 16) & 0xFF);
  tags[11] = static_cast<unsigned char>((vendorLen >> 24) & 0xFF);
  std::memcpy(tags.data() + 12, vendor, vendorLen);
  tags[12 + vendorLen] = 0;
  tags[13 + vendorLen] = 0;
  tags[14 + vendorLen] = 0;
  tags[15 + vendorLen] = 0;

  ogg_packet tagPacket;
  tagPacket.packet = tags.data();
  tagPacket.bytes = static_cast<long>(tags.size());
  tagPacket.b_o_s = 0;
  tagPacket.e_o_s = 0;
  tagPacket.granulepos = 0;
  tagPacket.packetno = mPacketNo++;
  ogg_stream_packetin(&mOggStream, &tagPacket);
}

CaptureErrors OpusOggWriter::write(const void *pFramesIn,
                                     ma_uint64 frameCount) {
  if (!mIsRecording) {
    return captureNotInited;
  }
  mPipeline.push(pFramesIn, static_cast<ma_uint32>(frameCount));
  return captureNoError;
}

void OpusOggWriter::writePacket(const unsigned char *packet, int packetSize) {
  ogg_packet op;
  op.packet = const_cast<unsigned char *>(packet);
  op.bytes = packetSize;
  op.b_o_s = 0;
  op.e_o_s = 0;
  op.granulepos = mGranulePos;
  op.packetno = mPacketNo++;

  ogg_stream_packetin(&mOggStream, &op);
  mGranulePos += (48000 * 20) / 1000; // 20 ms at 48 kHz

  flushPages();
}

void OpusOggWriter::flushPages() {
  ogg_page page;
  while (ogg_stream_pageout(&mOggStream, &page) != 0) {
    writeOggPage(&page);
  }
}

void OpusOggWriter::writeOggPage(const ogg_page *page) {
#ifndef __EMSCRIPTEN__
  if (mFile != nullptr) {
    fwrite(page->header, 1, page->header_len, mFile);
    fwrite(page->body, 1, page->body_len, mFile);
  }
#else
  mData.insert(mData.end(), page->header, page->header + page->header_len);
  mData.insert(mData.end(), page->body, page->body + page->body_len);
#endif
}

void OpusOggWriter::close() {
  if (!mIsRecording) {
    return;
  }

  mPipeline.flush();

  ogg_packet op;
  op.packet = nullptr;
  op.bytes = 0;
  op.b_o_s = 0;
  op.e_o_s = 1;
  op.granulepos = mGranulePos;
  op.packetno = mPacketNo++;
  ogg_stream_packetin(&mOggStream, &op);

  ogg_page page;
  while (ogg_stream_flush(&mOggStream, &page) != 0) {
    writeOggPage(&page);
  }

  ogg_stream_clear(&mOggStream);
  mPipeline.reset();

#ifndef __EMSCRIPTEN__
  if (mFile != nullptr) {
    fclose(mFile);
    mFile = nullptr;
  }
#else
  EM_ASM(
      {
        const data = new Uint8Array(HEAPU8.subarray($0, $0 + $1));
        const blob = new Blob([data], {type : 'audio/ogg'});
        if (window.showSaveFilePicker) {
          window.showSaveFilePicker({
                suggestedName : UTF8ToString($2) || 'output.opus',
                types : [ { description : 'Ogg Opus file', accept : {'audio/ogg' : ['.opus', '.ogg']} } ]
              })
              .then(handle => handle.createWritable())
              .then(writable => writable.write(blob))
              .then(() => writable.close())
              .catch(err => console.error('Error saving Opus file:', err));
        } else {
          const url = URL.createObjectURL(blob);
          const link = document.createElement('a');
          link.href = url;
          link.download = UTF8ToString($2) || 'output.opus';
          link.click();
          URL.revokeObjectURL(url);
        }
      },
      mData.data(), mData.size(), mFileName.c_str());
  mData.clear();
#endif

  mIsRecording = false;
  mGranulePos = 0;
  mPacketNo = 0;
}

bool OpusOggWriter::isRecording() const { return mIsRecording; }

} // namespace WriteAudio
