#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_recorder.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_recorder'
  s.version          = '0.0.1'
  s.summary          = 'A new Flutter FFI plugin project.'
  s.description      = <<-DESC
A new Flutter FFI plugin project.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }

  # This will ensure the source files in Classes/ are included in the native
  # builds of apps using this FFI plugin. Podspec does not support relative
  # paths, so Classes contains a forwarder C file that relatively imports
  # `../src/*` so that the C sources can be shared among all target platforms.
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.11'
  s.pod_target_xcconfig = { 
    'DEFINES_MODULE' => 'YES',
    "CLANG_CXX_LANGUAGE_STANDARD" => "c++17",
    # Enhanced optimization flags
    'OTHER_CFLAGS' => '-Ofast -march=native -mtune=native -ffast-math -flto -funroll-loops -msse -msse2 -msse3 -pthread -Wno-strict-prototypes',
    'OTHER_CPLUSPLUSFLAGS' => '-Ofast -march=native -mtune=native -ffast-math -flto -funroll-loops -msse -msse2 -msse3 -pthread -Wno-strict-prototypes',
    'GCC_OPTIMIZATION_LEVEL' => '3',
    # Add audio and threading optimization flags
    'GCC_PREPROCESSOR_DEFINITIONS' => 'MA_NO_RUNTIME_LINKING=1 NDEBUG=1 _REENTRANT=1',
    'HEADER_SEARCH_PATHS' => '$(inherited) $(PODS_TARGET_SRCROOT)/src'
  }
  s.swift_version = '5.0'
  s.framework  = ['CoreAudio', 'AudioToolbox', 'AVFoundation']
end
