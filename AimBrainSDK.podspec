Pod::Spec.new do |s|
  s.name                = "AimBrainSDK"
  s.version             = "0.6.5"
  s.summary             = "AimBrainSDK security library"
  s.homepage            = "https://aimbrain.github.io/aimbrain-api/"

  s.author              = "AimBrain"
  s.source              = { :git => "https://github.com/aimbrain/aimbrain-ios-sdk.git", :tag => s.version.to_s }

  s.platform            = :ios, '8.0'
  s.source_files        = 'Source/*.{h,m,swift}', 'Source/**/*.{h,m,swift}'
  s.resources           = 'Resources/*'
end
