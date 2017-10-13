source 'https://github.com/CocoaPods/Specs.git'

def ios_pods
    pod 'GoogleAPIClient/YouTube', '1.0.4', :inhibit_warnings => true
    pod 'Localytics', '4.3.0', :inhibit_warnings => true
    pod 'RBBAnimation', :git => 'https://github.com/wireapp/RBBAnimation', :commit => '7dd8d9a3cf610be5f7c1e4459692d555d70704c7'
    pod 'ARCollectionViewMasonryLayout', :git => 'https://github.com/wireapp/ARCollectionViewMasonryLayout', :tag => '2.3.0'
    pod 'SCSiriWaveformView', :git => 'https://github.com/wireapp/SCSiriWaveformView', :tag => 'v1.0.3'
end
    
    
target 'Wire-iOS' do

    platform :ios, '8.0'
    ios_pods

    post_install do |installer_representation|
        installer_representation.pods_project.targets.each do |target|
            target.build_configurations.each do |config|
                config.build_settings['APPLICATION_EXTENSION_API_ONLY'] = 'NO'
            end
        end
    end  
    
end


target 'Wire-iOS-Tests' do
    platform :ios, '8.0'
end

target 'WireExtensionComponents' do
    platform :ios, '8.0'
end

    
