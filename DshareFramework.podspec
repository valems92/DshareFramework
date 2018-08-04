Pod::Spec.new do |s|
  s.name         = "DshareFramework"
  s.version      = "1.1.0"
  s.summary      = "DshareFramework is a framework for sharing and getting descount"
  s.description  = <<-DESC
  DshareFramework take care of saving your data in firebase, givess you a lot of tools to manage you share app
  and provides you a chat
                   DESC
  s.homepage     = "http://EXAMPLE/DshareFramework"
  s.license      = "MIT"
  s.author       = "Dshare"
  s.source       = { :git => "https://github.com/valems92/DshareFramework.git", :tag => "1.1.0" }
  s.source_files = "DshareFramework"
  s.platform     = :ios, "10.0"

  s.dependency 'Firebase/Core'
  s.dependency 'Firebase/Database'
  s.dependency 'Firebase/Auth'
  s.dependency 'Firebase/Storage'
  s.dependency 'Firebase/Messaging'

end
