# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require 'gibbon/version'

Gem::Specification.new do |s|
  s.name        = "gibbon"
  s.version     = Gibbon::VERSION
  s.authors     = ["Amro Mousa"]
  s.email       = ["amromousa@gmail.com"]
  s.homepage    = "https://github.com/amro/gibbon"

  s.summary     = %q{A wrapper for MailChimp API 3.0}
  s.description = %q{Gibbon is a Ruby wrapper for MailChimp's Marketing API (version 3.0). Ruby method chains map onto API resource paths, so every documented resource is reachable without waiting on a gem update.}
  s.license     = "MIT"

  s.metadata = {
    "source_code_uri"   => "https://github.com/amro/gibbon",
    "changelog_uri"     => "https://github.com/amro/gibbon/blob/master/CHANGELOG.md",
    "bug_tracker_uri"   => "https://github.com/amro/gibbon/issues",
    "documentation_uri" => "https://rubydoc.info/gems/gibbon"
  }

  s.files         = `git ls-files`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  s.required_ruby_version = '>= 3.1.0'

  s.add_dependency('faraday', '>= 1.0')
  s.add_dependency('multi_json', '>= 1.11.0')

  s.add_development_dependency 'rake'
  s.add_development_dependency "rspec", "~> 3.13"
  s.add_development_dependency 'webmock', '~> 3.8'

end
