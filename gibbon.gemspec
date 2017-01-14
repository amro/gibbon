# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require 'gibbon/version'

Gem::Specification.new do |s|
  s.name        = "gibbon"
  s.version     = Gibbon::VERSION
  s.authors     = ["Amro Mousa"]
  s.email       = ["amromousa@gmail.com"]
  s.homepage    = "http://github.com/amro/gibbon"

  s.summary     = %q{A wrapper for MailChimp API 3.0 and Export API}
  s.description = %q{A wrapper for MailChimp API 3.0 and Export API}
  s.license     = "MIT"

  s.rubyforge_project = "gibbon"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  s.required_ruby_version = '>= 2.0.0'

  s.add_dependency('faraday', '>= 0.9.1')
  s.add_dependency('multi_json', '>= 1.11.0')

  s.add_development_dependency 'rake'
  s.add_development_dependency "rspec", "3.5.0"
  s.add_development_dependency 'webmock', '~> 1.21.0'

end
