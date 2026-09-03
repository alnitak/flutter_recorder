package flutter.recorder.flutter_recorder;

import android.util.Log;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.plugins.FlutterPlugin;

/**
 * Keeps flutter_recorder's process-global native state in step with the lifetime
 * of the FlutterEngine that owns it.
 */
public final class FlutterRecorderPlugin implements FlutterPlugin {
    private static final String TAG = "FlutterRecorderPlugin";

    private static boolean nativeLibraryLoaded = false;

    private static native boolean
        nativeClearDartCallbackRegistrationsForEngine(long engineId);

    private static native boolean
        nativeRequestEngineTeardownForEngine(long engineId);

    @Nullable private FlutterEngine flutterEngine;
    @Nullable private Long engineId;
    @Nullable private FlutterEngine.EngineLifecycleListener lifecycleListener;

    private boolean teardownRequested = false;

    private static synchronized boolean ensureNativeLibraryLoaded() {
        if (nativeLibraryLoaded) {
            return true;
        }

        try {
            System.loadLibrary("flutter_recorder_plugin");
            nativeLibraryLoaded = true;
            return true;
        } catch (UnsatisfiedLinkError error) {
            try {
                System.loadLibrary("flutter_recorder");
                nativeLibraryLoaded = true;
                return true;
            } catch (UnsatisfiedLinkError fallbackError) {
                return false;
            }
        }
    }

    @SuppressWarnings("deprecation")
    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        final FlutterEngine engine = binding.getFlutterEngine();
        flutterEngine = engine;
        engineId = engine.getEngineId();
        teardownRequested = false;

        final FlutterEngine.EngineLifecycleListener listener =
            new FlutterEngine.EngineLifecycleListener() {
                @Override
                public void onPreEngineRestart() {
                    // Hot restart replaces the Dart isolate but does not detach
                    // plugins, and the engine id is unchanged -- so without this
                    // the registered NativeCallables silently go stale.
                    clearDartCallbackRegistrations();
                }

                @Override
                public void onEngineWillDestroy() {
                    requestEngineTeardown();
                }
            };
        lifecycleListener = listener;
        engine.addEngineLifecycleListener(listener);
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        final FlutterEngine engine = flutterEngine;
        final FlutterEngine.EngineLifecycleListener listener = lifecycleListener;

        if (engine != null && listener != null) {
            engine.removeEngineLifecycleListener(listener);
        }

        requestEngineTeardown();

        flutterEngine = null;
        engineId = null;
        lifecycleListener = null;
    }

    private void clearDartCallbackRegistrations() {
        final Long id = engineId;
        if (id == null || !ensureNativeLibraryLoaded()) {
            return;
        }

        try {
            nativeClearDartCallbackRegistrationsForEngine(id);
        } catch (UnsatisfiedLinkError error) {
            Log.w(TAG, "Unable to clear Dart callback registrations", error);
        }
    }

    private void requestEngineTeardown() {
        final Long id = engineId;
        if (id == null || teardownRequested) {
            return;
        }

        if (!ensureNativeLibraryLoaded()) {
            return;
        }

        try {
            teardownRequested = nativeRequestEngineTeardownForEngine(id);
        } catch (UnsatisfiedLinkError error) {
            Log.w(TAG, "Unable to request native engine teardown", error);
        }
    }
}
