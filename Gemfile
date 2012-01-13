source "http://rubygems.org"

gem "json", "> 1.4.0"
gem "httparty", "> 0.6.0"
gem "rdoc"

group :development, :test do
  gem "shoulda", ">= 0"
  gem "bundler", "~> 1.0"
  gem "jeweler", "~> 1.5"
  gem "rcov", ">= 0"
  gem "mocha", "> 0.9.11"

  unless ENV["CI"]
    gem "ruby-debug19", :require => "ruby-debug", :platforms => [:ruby_19]
    gem "ruby-debug", :platforms => [:ruby_18]
  end
end
