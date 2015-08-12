Pod::Spec.new do |s|
  s.name             = "Swifter"
  s.version          = "1.0.1"
  s.summary          = "Tiny http server engine written in Swift programming language."
  s.homepage         = "https://github.com/glock45/swifter"
  s.license          = { :type => 'Copyright', :file => 'LICENSE' }
  s.author           = { "Damian Kołakowski" => "kolakowski.damian@gmail.com" }
  s.source           = { :git => "https://github.com/glock45/swifter.git"}
  s.platform         = :ios
  s.requires_arc     = true
  s.source_files     = 'Common/*.{h,m,swift}'
end
