load 'remove_unsupported_libraries.rb'
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '9.0'
use_frameworks!
inhibit_all_warnings!
target 'VehicleGPS' do
	use_frameworks!
  pod 'NMSSH'
  pod 'MBProgressHUD', '~> 1.1'
  pod 'Socket.IO-Client-Swift', '~> 15.2.0'
  pod 'SwiftLint'
  pod "fastCSV"
  pod 'Pulley'
end

# define unsupported pods
def unsupported_pods
   ['NMSSH']
end

# install all pods except unsupported ones
post_install do |installer|
   configure_support_catalyst installer, unsupported_pods
end