#ifndef COMMON_H
#define COMMON_H


#ifdef __ANDROID__
    #define _IS_ANDROID_
#elif __linux__
    #define _IS_LINUX_
#elif _WIN32 | WIN32 | __WIN32 | _WIN64
    #define _IS_WIN_
#elif  __APPLE__
    #include <TargetConditionals.h>
    #define _IS_MACOS_
    /// these targets doesn't work!
    #ifdef TARGET_OS_IPHONE
         // iOS
    #elif TARGET_IPHONE_SIMULATOR
        // iOS Simulator
    #elif TARGET_OS_MAC
        #define _IS_MACOS_
    #else
        // Unsupported platform
    #endif
#else
    #define _WASM_
#endif

#ifdef _IS_WIN_
#define NOMINMAX
#include <windows.h>
#define FFI_PLUGIN_EXPORT __declspec(dllexport)
#endif

#ifdef _IS_ANDROID_
#include <android/log.h>
#endif

#if defined _IS_LINUX_ || defined _IS_MACOS_ || defined _IS_ANDROID_ || defined _WASM_
#include <pthread.h>
#include <unistd.h>
#include <stdbool.h>
#define FFI_PLUGIN_EXPORT __attribute__((visibility("default"))) __attribute__((used))
#endif

typedef void (*dartSilenceChangedCallback_t)(bool *, float *);

typedef void (*dartStreamDataCallback_t)(const unsigned char * data, const int dataLength);

// To be used by `NativeCallable` since it will be called inside the audio thread,
// these functions must return void.
extern void (*dartSilenceChangedCallback)(bool *, float *);

// Native functions can be called from any thread. It will eventually call `dartSilenceChangedCallback`.
extern void (*nativeSilenceChangedCallback)(bool *, float *);

extern void (*dartStreamDataCallback)(const unsigned char * data, const int dataLength);

extern void (*nativeStreamDataCallback)(const unsigned char * data, const int dataLength);

#endif // COMMON_H
