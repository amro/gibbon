# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name        = "gibbon"
  s.version     = "0.5.0"
  s.authors     = ["Amro Mousa"]
  s.email       = ["amromousa@gmail.com"]
  s.homepage    = "http://github.com/amro/gibbon"

  s.summary     = %q{A wrapper for MailChimp API 2.0 and Export API 1.0}
  s.description = %q{A wrapper for MailChimp API 2.0 and Export API 1.0}
  s.license     = "MIT"

  s.post_install_message = "Important: Gibbon versions 0.5.0 and newer include breaking changes for all API calls as it now supports MailChimp API 2.0"
  
  s.rubyforge_project = "gibbon"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency('httparty')
  s.add_dependency('multi_json', '>= 1.3.4')

  s.add_development_dependency('rake')
  s.add_development_dependency('debugger')
  s.add_development_dependency('shoulda')
  s.add_development_dependency('mocha')
end
