source "https://rubygems.org"

gemspec

group :development do
  gem "mocha"
  gem "webmock"
  gem "rack-test"
  gem "rake"
  gem "rubocop"
  gem "rubocop-performance"
  gem "smart_proxy", git: "https://github.com/theforeman/smart-proxy", branch: "develop"
  gem "test-unit"
  gem "pry"
  gem "json-diff"
  if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("2.6.0")
    gem "rufo"
  end
end
