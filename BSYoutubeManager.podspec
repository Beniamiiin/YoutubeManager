Pod::Spec.new do |spec|
  spec.name         = 'BSYoutubeManager'
  spec.version      = '0.1'
  spec.author       = { 'Beniamin' => 'beniamin.sarkisyan@gmail.com' }
  spec.homepage     = 'https://github.com/BenjaminSarkisyan/YoutubeManager'
  spec.summary      = 'Youtube manager, load video from youtube channel'
  spec.source       = { :git => 'https://github.com/BenjaminSarkisyan/YoutubeManager.git' }
  spec.source_files = 'Classes/BSYoutubeManager.{h,m}', 'Classes/BSYoutubeVideo.{h,m}', 'YoutubeSDK/**.{h.m}', 'YoutubeSDK/**.a'
  spec.requires_arc = true
end