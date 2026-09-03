#import <Flutter/Flutter.h>

/**
 * Keeps flutter_recorder's process-global native state in step with the lifetime
 * of the FlutterEngine that owns it.
 *
 * This plugin only observes the engine's lifetime. Ownership and teardown
 * decisions belong to the shared C++ implementation.
 *
 * It does no native work at registration.
 */
@interface FlutterRecorderPlugin : NSObject <FlutterPlugin>
@end
