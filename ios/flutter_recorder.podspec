#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_recorder.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_recorder'
  s.version          = '0.0.1'
  s.summary          = 'A low-level audio recorder plugin which uses miniaudio as backend.'
  s.description      = <<-DESC
A low-level audio recorder plugin which uses miniaudio as backend.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }

  s.source           = { :path => '.' }
  s.source_files = [
    'flutter_recorder/Sources/flutter_recorder/FlutterRecorderPlugin.mm',
    'flutter_recorder/include/FlutterRecorderPlugin.h',
  ]
  s.public_header_files = 'flutter_recorder/include/FlutterRecorderPlugin.h'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'HEADER_SEARCH_PATHS' => ['$(PODS_TARGET_SRCROOT)/../src'],
    'OTHER_LDFLAGS' => '$(inherited) -undefined dynamic_lookup',
  }
  s.swift_version = '5.0'
end
