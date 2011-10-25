require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "gibbon"
  gem.homepage = "http://github.com/amro/gibbon"
  gem.license = "MIT"
  gem.summary = %Q{Gibbon is a simple API wrapper for interacting with MailChimp API 1.3}
  gem.description = %Q{Gibbon is a simple API wrapper for interacting with MailChimp API version 1.3.}
  gem.email = "amromousa@gmail.com"
  gem.authors = ["Amro Mousa"]
  # Include your dependencies below. Runtime dependencies are required when using your gem,
  # and development dependencies are only needed for development (ie running rake tasks, tests, etc)
  gem.add_runtime_dependency 'httparty', '> 0.6.0'
  gem.add_runtime_dependency 'activesupport', '>= 2.3.14'
  gem.add_runtime_dependency 'json', '> 1.4.0'
  gem.add_development_dependency 'httparty', '> 0.6.0'
  gem.add_development_dependency 'json', '> 1.4.0'
  gem.add_development_dependency 'mocha', '> 0.9.11'
  #gem.add_development_dependency 'rspec', '> 1.2.3'
end
Jeweler::RubygemsDotOrgTasks.new

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

require 'rcov/rcovtask'
Rcov::RcovTask.new do |test|
  test.libs << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

task :default => :test

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "gibbon #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
