require 'bundler/gem_tasks'
require 'rake/testtask'

Rake::TestTask.new do |t|
  t.test_files = FileList['test/unit/test_*.rb', 'test/functional/test_*.rb']
end

desc 'Run tests'
task :default => :test
