#pragma once

#ifndef FLUTTER_RECORDER_DART_CALLBACK_GATE_H
#define FLUTTER_RECORDER_DART_CALLBACK_GATE_H

#include <cstdint>
#include <mutex>
#include <shared_mutex>

/// One gate that every Dart callable native code holds must pass through.
///
/// Retiring a Dart trampoline is not "store nullptr over the pointer". A
/// thread that has already loaded the pointer will still call it, and the
/// isolate that owns it may be gone by then — a hot restart or a destroyed
/// FlutterEngine takes the isolate away without native code being asked first.
/// Retirement therefore has to guarantee two things at once:
///
///   * no invocation is in flight when it returns, and
///   * no invocation can start afterwards.
///
/// Only a lock gives that. Invocation takes it shared (so the audio thread
/// never queues behind an unrelated callback), retirement takes it exclusive.
namespace dart_callbacks
{

  /// Used where no FlutterEngine lifecycle exists: the web build, the desktop
  /// embedders, and any host that does not run the Android/iOS lifecycle plugin.
  constexpr int64_t kNoEngineId = -1;

  /// The generation of a registration that was never made, or has been retired.
  /// Never live, so it can be the default for a source that has no callbacks.
  constexpr uint64_t kNoGeneration = 0;

  namespace detail
  {
    struct GateState
    {
      std::shared_mutex mutex;
      /// The only generation allowed to run, or kNoGeneration when retired.
      uint64_t liveGeneration = kNoGeneration;
      /// Monotonic source of generations. Never reused.
      uint64_t lastGeneration = kNoGeneration;
      /// Which FlutterEngine published the live registration.
      int64_t ownerEngineId = kNoEngineId;
    };

    /// Deliberately never destroyed: detached teardown workers and the audio
    /// thread can outlive main(), and locking a destroyed mutex is worse than
    /// leaking one small object.
    inline GateState &gate()
    {
      static GateState *state = new GateState();
      return *state;
    }
  } // namespace detail

#ifdef __EMSCRIPTEN__

  /// The web has nothing for this gate to protect, so it compiles away.
  class InvocationPass
  {
  public:
    bool isLive(uint64_t) const { return true; }
  };

#else

  /// Held for the duration of one Dart trampoline invocation.
  ///
  /// Construct it *before* loading the callable pointer, and keep it alive
  /// across the call.
  class InvocationPass
  {
  public:
    InvocationPass()
        : mLock(detail::gate().mutex),
          mLiveGeneration(detail::gate().liveGeneration) {}

    /// Whether a callable registered at [registrationGeneration] may run.
    bool isLive(uint64_t registrationGeneration) const
    {
      return registrationGeneration != kNoGeneration &&
             registrationGeneration == mLiveGeneration;
    }

  private:
    std::shared_lock<std::shared_mutex> mLock;
    uint64_t mLiveGeneration;
  };

#endif // __EMSCRIPTEN__

  /// Exclusive access for publishing or retiring registrations.
  class Registration
  {
  public:
    Registration() : mLock(detail::gate().mutex) {}

    /// Publish a registration owned by [ownerEngineId] and return its
    /// generation. Any earlier registration is left permanently inert.
    uint64_t claim(int64_t ownerEngineId)
    {
      detail::GateState &state = detail::gate();
      if (state.liveGeneration != kNoGeneration &&
          state.ownerEngineId == ownerEngineId)
      {
        return state.liveGeneration;
      }
      state.ownerEngineId = ownerEngineId;
      state.liveGeneration = ++state.lastGeneration;
      return state.liveGeneration;
    }

    /// Whether [engineId] owns the live registration. A caller with no engine
    /// lifecycle (kNoEngineId) matches a registration published the same way.
    bool isOwnedBy(int64_t engineId) const
    {
      const detail::GateState &state = detail::gate();
      return state.liveGeneration != kNoGeneration &&
             state.ownerEngineId == engineId;
    }

    /// Retire the live registration if [engineId] owns it. Returns false when
    /// somebody else does, so a detaching engine never retires another's.
    bool retire(int64_t engineId)
    {
      if (!isOwnedBy(engineId))
        return false;

      retireAll();
      return true;
    }

    /// Retire whatever is live, whoever owns it.
    void retireAll()
    {
      detail::GateState &state = detail::gate();
      state.liveGeneration = kNoGeneration;
      state.ownerEngineId = kNoEngineId;
    }

    uint64_t generation() const { return detail::gate().liveGeneration; }

  private:
    std::unique_lock<std::shared_mutex> mLock;
  };

  /// The generation a source-owned registration must record when it stores its
  /// callables.
  inline uint64_t currentGeneration()
  {
    std::shared_lock<std::shared_mutex> lock(detail::gate().mutex);
    return detail::gate().liveGeneration;
  }

} // namespace dart_callbacks

#endif // FLUTTER_RECORDER_DART_CALLBACK_GATE_H
