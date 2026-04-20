Pod::Spec.new do |s|
  s.name             = 'FaceBioFlutter'
  s.version          = '1.0.0'
  s.summary          = 'FaceBio native iOS SDK'
  s.homepage         = 'https://example.com'
  s.license          = { :type => 'MIT' }
  s.author           = { 'FaceBio' => 'dev@example.com' }
  s.platform         = :ios, '15.0'
  s.source           = { :path => '.' }
  s.vendored_frameworks = 'Frameworks/FaceBioFlutter.xcframework'
  s.pod_target_xcconfig = {
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386 x86_64 arm64'
  }
  s.user_target_xcconfig = {
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386 x86_64 arm64'
  }
end
