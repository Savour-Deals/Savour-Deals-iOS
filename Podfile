# Uncomment the next line to define a global platform for your project
platform :ios, 9.0

inhibit_all_warnings!

target 'Savour' do
  pod 'Firebase'
  pod 'Firebase/Auth'
  pod 'Firebase/Core'
  pod 'Firebase/Database'
  pod 'SDWebImage/WebP'
  pod 'Firebase/Storage'
  pod 'FirebaseUI/Storage'
  pod 'FBSDKCoreKit'
  pod 'FBSDKLoginKit'
  pod 'FBSDKShareKit'
  pod 'Pulsator'
  pod 'Charts'
  pod 'Firebase/Messaging'
  pod 'OneSignal'
  pod 'AcknowList'
  pod 'GeoFire'
# pod 'Firebase/Firestore'

  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Savour

end

target 'OneSignalNotificationServiceExtension' do
  pod 'OneSignal'
  use_frameworks!
end


post_install do | installer |
  require 'fileutils'
  FileUtils.cp_r('Pods/Target Support Files/Pods-Savour/Pods-Savour-acknowledgements.plist', 'Savour/Acknowledgements.plist', :remove_destination => true)
end
