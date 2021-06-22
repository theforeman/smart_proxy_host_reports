require "rake"
require "rake/testtask"

desc "Default: run tests."
task default: :test

desc "Test the plugin"
Rake::TestTask.new(:test) do |t|
  t.libs << "."
  t.libs << "lib"
  t.libs << "test"
  t.test_files = FileList["test/**/*_test.rb"]
  t.verbose = true
end
