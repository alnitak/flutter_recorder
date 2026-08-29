#ifndef FAST_MUTEX_H
#define FAST_MUTEX_H

#if defined(__EMSCRIPTEN__) && defined(MA_ENABLE_AUDIO_WORKLETS)
#include <atomic>
#include <cstdint>

// musl's pthread mutexes cannot be used on the AudioWorklet rendering
// thread: Emscripten starts wasm-worker threads (AudioWorklets included) with a
// null thread pointer, so pthread_mutex_lock blocks on a futex wait, which
// aborts on the worklet thread (assertion in futex_wait_main_browser_thread).
// This recursive spin mutex is keyed on the per-thread TLS base (__builtin_wasm_tls_base)
// and never calls into futex code.
class FastMutex {
public:
    FastMutex() : mOwner(0), mCount(0) {}

    void lock() {
        const uint32_t self = emscriptenThreadId();
        if (mOwner.load(std::memory_order_relaxed) == self) {
            mCount++;
            return;
        }
        uint32_t expected = 0;
        while (!mOwner.compare_exchange_weak(expected, self,
                std::memory_order_acquire, std::memory_order_relaxed)) {
            expected = 0;
        }
        mCount = 1;
    }

    bool try_lock() {
        const uint32_t self = emscriptenThreadId();
        if (mOwner.load(std::memory_order_relaxed) == self) {
            mCount++;
            return true;
        }
        uint32_t expected = 0;
        if (!mOwner.compare_exchange_strong(expected, self,
                std::memory_order_acquire, std::memory_order_relaxed)) {
            return false;
        }
        mCount = 1;
        return true;
    }

    void unlock() {
        if (--mCount == 0) {
            mOwner.store(0, std::memory_order_release);
        }
    }

private:
    static uint32_t emscriptenThreadId() {
        return (uint32_t)(uintptr_t)__builtin_wasm_tls_base();
    }

    std::atomic<uint32_t> mOwner;
    uint32_t mCount;
};
#else
#include <mutex>
using FastMutex = std::recursive_mutex;
#endif

#endif // FAST_MUTEX_H
