require "rake/testtask"

rdoc_sources = %w(hanna/rdoctask rdoc/task rake/rdoctask)
begin
  require rdoc_sources.shift
rescue LoadError
  retry
end

begin
  require "metric_fu" if RUBY_VERSION < "1.9"
rescue LoadError
end

begin
  require "mg"
  MG.new("rack-unbasic.gemspec")
rescue LoadError
end

desc "Default: run all tests"
task :default => :test

desc "Run library tests"
Rake::TestTask.new do |t|
  t.test_files = FileList["test/**/test_*.rb"]
end

Rake::RDocTask.new do |rd|
  rd.main = "README"
  rd.title = "Documentation for Rack::Unbasic"
  rd.rdoc_files.include("README.rdoc", "LICENSE", "lib/**/*.rb")
  rd.rdoc_dir = "doc"
end
