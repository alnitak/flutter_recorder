// On Apple platforms, miniaudio.h includes AVFoundation Objective-C headers,
// so the miniaudio backend must be compiled as Objective-C++.
// The build hook compiles this shim (clang treats .mm as Objective-C++)
// instead of the .cpp directly.

#include "miniaudio.cpp"
