require 'rake/testtask'

task :default => :test

Rake::TestTask.new do |t|
  require 'turn/autorun'
  
  t.libs.push "lib"
  t.test_files = FileList['test/*_test.rb']
  t.verbose = true
end