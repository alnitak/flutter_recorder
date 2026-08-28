// This header uses the preprocessor to rename the Objective-C class
// ma_ios_notification_handler to a unique name for this plugin, avoiding
// duplicate symbol conflict when other plugins also include miniaudio.

#ifndef MINIAUDIO_OBJC_PREFIX_H
#define MINIAUDIO_OBJC_PREFIX_H

#ifdef __APPLE__
#define ma_ios_notification_handler fr_ma_ios_notification_handler
#endif

#endif // MINIAUDIO_OBJC_PREFIX_H
