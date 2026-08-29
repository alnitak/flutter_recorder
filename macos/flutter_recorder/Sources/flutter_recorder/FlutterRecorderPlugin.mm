#import "FlutterRecorderPlugin.h"

#include "engine_lifecycle.h"

/// The engine-local channel Dart uses to hand this plugin its engine id.
static NSString *const kEngineLifecycleChannel =
    @"flutter_recorder/engine_lifecycle";

/// Matches `kNoEngineId` in the shared C++ implementation.
static const int64_t kNoEngineId = -1;

@implementation FlutterRecorderPlugin {
  int64_t _engineId;
  BOOL _hasEngineId;
}

+ (void)registerWithRegistrar:(id<FlutterPluginRegistrar>)registrar {
  FlutterRecorderPlugin *instance = [[FlutterRecorderPlugin alloc] init];
  FlutterMethodChannel *channel =
      [FlutterMethodChannel methodChannelWithName:kEngineLifecycleChannel
                                  binaryMessenger:registrar.messenger];
  [registrar addMethodCallDelegate:instance channel:channel];
  [registrar publish:instance];
}

- (instancetype)init {
  self = [super init];
  if (self != nil) {
    _engineId = kNoEngineId;
    _hasEngineId = NO;
    [[NSNotificationCenter defaultCenter]
        addObserver:self
           selector:@selector(applicationWillTerminate:)
               name:NSApplicationWillTerminateNotification
             object:nil];
  }
  return self;
}

- (void)applicationWillTerminate:(NSNotification *)notification {
  if (_hasEngineId) {
    const int64_t engineId = _engineId;
    _hasEngineId = NO;
    _engineId = kNoEngineId;
    flutter_recorder_clearDartCallbackRegistrationsForEngine(engineId);
  }
}

- (void)handleMethodCall:(FlutterMethodCall *)call
                  result:(FlutterResult)result {
  if (![call.method isEqualToString:@"prepareEngineInit"]) {
    result(FlutterMethodNotImplemented);
    return;
  }

  NSDictionary *arguments = call.arguments;
  if (![arguments isKindOfClass:[NSDictionary class]]) {
    result([FlutterError errorWithCode:@"invalid_arguments"
                               message:@"Expected a map of prepare arguments."
                               details:nil]);
    return;
  }

  NSNumber *engineIdArgument = arguments[@"engineId"];
  NSNumber *epochArgument = arguments[@"shutdownEpoch"];
  if (![engineIdArgument isKindOfClass:[NSNumber class]] ||
      ![epochArgument isKindOfClass:[NSNumber class]]) {
    result([FlutterError
        errorWithCode:@"invalid_arguments"
              message:@"Expected an engine id and a shutdown epoch."
              details:nil]);
    return;
  }

  const int64_t engineId = [engineIdArgument longLongValue];
  if (engineId == kNoEngineId) {
    result([FlutterError
        errorWithCode:@"invalid_engine_id"
              message:@"The engine id is the no-engine sentinel."
              details:nil]);
    return;
  }

  const uint64_t shutdownEpoch =
      (uint64_t)[epochArgument unsignedLongLongValue];

  if (!flutter_recorder_prepareEngineInitForRequest(engineId, shutdownEpoch)) {
    result([FlutterError
        errorWithCode:@"stale_prepare"
              message:@"This initialization was superseded by a shutdown."
              details:nil]);
    return;
  }

  _engineId = engineId;
  _hasEngineId = YES;

  // Hot-restart recovery
  flutter_recorder_clearDartCallbackRegistrationsForEngine(engineId);

  result(@(YES));
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];

  if (!_hasEngineId) {
    return;
  }

  const int64_t engineId = _engineId;
  _hasEngineId = NO;
  _engineId = kNoEngineId;

  flutter_recorder_requestEngineTeardownForEngine(engineId);
}

@end
