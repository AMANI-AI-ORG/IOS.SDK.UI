Pod::Spec.new do |s|
  s.name = 'AmaniUI'
  s.version = '1.4.8-alpha06'
  s.license = {
    :type => 'Copyright',
    :text => "Copyright 2026\nAmani Ai AŞ."
  }
  s.swift_versions = '5.0'
  s.requires_arc = true
  s.homepage = 'http://www.amani.ai/'
  s.authors = { 'Amani Ai' => 'admin@amani.ai' }
  s.summary = 'Amani UI SDK'
  s.description = 'The Amani Software Development Kit UI package.'
  s.source = { :path => '.' }
  s.documentation_url = 'https://documentation.amani.ai'
  s.platform = :ios, '13.0'
  s.pod_target_xcconfig = {
    'OTHER_LDFLAGS' => '$(inherited) -weak_framework CryptoKit -weak_framework CoreNFC -weak_framework CryptoTokenKit'
  }

  s.default_subspec = 'Core'

  s.subspec 'Core' do |core|
    core.source_files = 'Sources/AmaniUI/**/*.{h,m,swift}'
    core.exclude_files = [
      'Sources/AmaniUI/SpeechVerifierIntegration/**/*',
      'AmaniUnitTests/**/*',
      'AmaniUI.xcodeproj/**/*'
    ]
    core.resource_bundles = {
      'AmaniUI' => ['Sources/AmaniUI/**/*.{xib,storyboard,xcassets,xcprivacy}']
    }
    core.dependency 'lottie-ios', '~> 4.5.0'
    core.dependency 'AmaniSDK', '~> 3.7.9'
  end

  s.subspec 'SpeechVerifier' do |speech|
    speech.dependency 'AmaniUI/Core'
    speech.dependency 'AmaniSpeechVerifier', '~> 1.0'
    speech.source_files = 'Sources/AmaniUI/SpeechVerifierIntegration/**/*.swift'
    speech.pod_target_xcconfig = {
      'OTHER_SWIFT_FLAGS' => '$(inherited) -D AMANI_SPEECH_VERIFIER_ENABLED'
    }
  end
end
