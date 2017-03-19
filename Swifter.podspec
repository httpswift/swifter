Pod::Spec.new do |s|

  s.name                  = "Swifter"
  s.version               = "1.3.3"
  s.summary               = "Tiny http server engine written in Swift programming language."
  s.homepage              = "https://github.com/glock45/swifter"
  s.license               = { :type => 'Copyright', :file => 'LICENSE' }
  s.author                = { "Damian Kołakowski" => "kolakowski.damian@gmail.com" }
  s.ios.deployment_target = "8.0"
  s.osx.deployment_target = "10.9"
  s.tvos.deployment_target = "9.0"
  s.source                = { :git => "https://github.com/glock45/swifter.git", :tag => "1.3.3" }
  s.source_files          = 'Sources/*.{h,m,swift}'

end
