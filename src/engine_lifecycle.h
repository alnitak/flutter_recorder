#pragma once

#ifndef FLUTTER_RECORDER_ENGINE_LIFECYCLE_H
#define FLUTTER_RECORDER_ENGINE_LIFECYCLE_H

#include <stdbool.h>
#include <stdint.h>

#ifndef FLUTTER_RECORDER_H
#include "flutter_recorder.h"
#endif

/// The FlutterEngine lifecycle entry points.
///
/// Reached from Dart over FFI, Android plugin over JNI, and iOS/macOS plugins
/// from Objective-C++. All three drive the same lifecycle claim and generation
/// state.
#ifdef __cplusplus
extern "C"
{
#endif

  /// Claim the native engine for [owner_engine_id] before its initialization
  /// is dispatched, and invalidate any teardown queued by a previous engine.
  /// -1 means "no engine lifecycle available on this platform".
  FFI_PLUGIN_EXPORT void prepareEngineInit(int64_t owner_engine_id);

  /// The epoch a prepare request must quote to be accepted.
  FFI_PLUGIN_EXPORT uint64_t currentEngineShutdownEpoch(void);

  /// Take the claim prepareEngineInit() would take, but only if no shutdown has
  /// been requested since [shutdown_epoch] was read. Returns whether it did.
  FFI_PLUGIN_EXPORT bool prepareEngineInitForRequest(int64_t owner_engine_id,
                                                     uint64_t shutdown_epoch);

  /// Retire every Dart callable owned by [engine_id].
  FFI_PLUGIN_EXPORT bool clearDartCallbackRegistrationsForEngine(
      int64_t engine_id);

  /// Retire all Dart callables regardless of engine ID.
  FFI_PLUGIN_EXPORT void clearDartCallbackRegistrations(void);

  /// Retire [engine_id]'s callables and queue the recorder teardown if owned.
  FFI_PLUGIN_EXPORT bool requestEngineTeardownForEngine(int64_t engine_id);

  /// Invoked as a Dart NativeFinalizer when an isolate is destroyed/restarted.
  FFI_PLUGIN_EXPORT void retireDartCallbacksFinalizer(void *token);

#ifdef __cplusplus
}
#endif

#endif // FLUTTER_RECORDER_ENGINE_LIFECYCLE_H
