# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require 'gibbon/version'

Gem::Specification.new do |s|
  s.name        = "gibbon"
  s.version     = Gibbon::VERSION
  s.authors     = ["Amro Mousa"]
  s.email       = ["amromousa@gmail.com"]
  s.homepage    = "http://github.com/amro/gibbon"

  s.summary     = %q{A wrapper for MailChimp API 2.0 and Export API 1.0}
  s.description = %q{A wrapper for MailChimp API 2.0 and Export API 1.0}
  s.license     = "MIT"

  s.post_install_message = "IMPORTANT: Gibbon now targets MailChimp API 2.0, which is substantially different from API 1.3.\n \
                            Please use Gibbon 0.4.6 if you need to use API 1.3.\nIf you're upgrading from <0.5.0 your code WILL break."

  s.rubyforge_project = "gibbon"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency('httparty')
  s.add_dependency('multi_json', '>= 1.9.0')

  s.add_development_dependency 'rake'
  s.add_development_dependency "rspec", "3.1.0"

end
