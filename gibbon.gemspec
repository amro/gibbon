# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name        = "gibbon"
  s.version     = "0.4.2"
  s.authors     = ["Amro Mousa"]
  s.email       = ["amromousa@gmail.com"]
  s.homepage    = "http://github.com/amro/gibbon"

  s.summary     = %q{A simple wrapper for MailChimp's primary and export APIs}
  s.description = %q{A simple wrapper for MailChimp's primary and export APIs}
  s.license     = "MIT"

  s.post_install_message = "Warning: Gibbon versions 0.4.0 and newer include breaking changes like throwing exceptions by default!\n" +
                           "Please read more at http://github.com/amro/gibbon before upgrading from 0.3.x!"
  
  s.rubyforge_project = "gibbon"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency('httparty')
  s.add_dependency('multi_json')

  s.add_development_dependency('rake')
  s.add_development_dependency('debugger')
  s.add_development_dependency('shoulda')
  s.add_development_dependency('mocha')
end
