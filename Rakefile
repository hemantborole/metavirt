require 'rubygems' 
require 'micronaut/rake_task'
require 'rake/testtask'

desc "Run all micronaut examples"
Micronaut::RakeTask.new :examples do |t|
  t.pattern = "examples/**/*_example.rb"
end

desc "Run all micronaut examples using rcov"
Micronaut::RakeTask.new :coverage do |t|
  t.pattern = "test/**/*_example.rb"
  # t.rcov = true
  # t.rcov_opts = "--exclude \"examples/*,gems/*,db/*,/Library/Ruby/*,config/*\" --text-summary  --sort coverage --no-validator-links" 
end

# Rake::TestTask.new do |t|
#   t.pattern = "test/**/test_*.rb"
#   t.verbose = true
# end
# task :default => :test

