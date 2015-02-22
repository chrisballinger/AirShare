Pod::Spec.new do |s|
  s.name             = "AirShare"
  s.version          = "0.1.0"
  s.summary          = "Bluetooth LE / Multipeer data sharing library"
  s.homepage         = "https://github.com/chrisballinger/AirShare"
  s.license          = 'MPLv2'
  s.author           = { "Chris Ballinger" => "chris@chatsecure.org" }
  s.source           = { :git => "https://github.com/chrisballinger/AirShare.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/ChatSecure'

  s.ios.deployment_target = '7.0'
  s.osx.deployment_target = '10.8'
  s.requires_arc = true

  s.default_subspec = 'AirShare'

  s.dependency 'libsodium'
  s.dependency 'CocoaLumberjack', '~> 1.9'
  s.dependency 'PureLayout', '~> 2.0'
  s.frameworks = 'CoreBluetooth'

  s.subspec 'AirShare' do |ss|
    ss.source_files = 'AirShare/*.{h,m}'
  end

  s.subspec 'UIKit' do |ss|
    ss.ios.source_files = 'AirShare/UIKit/*.{h,m}'
    ss.dependency 'AirShare/AirShare'
  end
end
