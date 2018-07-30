Pod::Spec.new do |s|
  s.name         = "DshareFramework"
  s.version      = "0.0.1"
  s.summary      = "DshareFramework is a framework for sharing and getting descount"
  s.description  = <<-DESC
  DshareFramework take care of saving your data in firebase, givess you a lot of tools to manage you share app
  and provides you a chat
                   DESC
  s.homepage     = "http://EXAMPLE/DshareFramework"
  s.license      = "MIT"
  s.author       = "Share"
  s.source       = { :path => "." }
  s.source_files = "DshareFramework"
  s.swift_version = "4" 
  # s.platform     = :ios, "8.0"

  s.dependency 'Firebase/Core'
  s.dependency 'Firebase/Database'
  s.dependency 'Firebase/Auth'
  s.dependency 'Firebase/Storage'
  s.dependency 'Firebase/Messaging'
  s.dependency 'JSQMessagesViewController'

end
