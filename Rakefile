require 'bundler'
Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'
require 'spree/testing_support/extension_rake'

desc 'Generates a dummy app for testing'
task :test_app do
  ENV['LIB_NAME'] = 'spree_emerchantpay_genesis'
  Rake::Task['extension:test_app'].invoke
end

RSpec::Core::RakeTask.new(:spec)
RSpec::Core::RakeTask.new(:spec_junit) do |t|
  t.rspec_opts = ['--format RspecJunitFormatter', '--out rspec_report.xml']
  t.pattern    = '**/*_spec.rb'
end

task :rspec, [:format] do |_task, args|
  if Dir['spec/dummy'].empty?
    Rake::Task[:test_app].invoke
    Dir.chdir('../../')
  end

  case args.format
  when 'junit'
    Rake::Task[:spec_junit].invoke
  else
    Rake::Task[:spec].invoke
  end
end

require 'rubocop/rake_task'
RuboCop::RakeTask.new(:rubocop_default)
RuboCop::RakeTask.new(:rubocop_progress) do |t|
  t.formatters = %w(progress)
  t.options    = %w(--out rubocop_report.txt)
end

task :test do
  Rake::Task[:rspec].invoke('')
end

task :test_junit do
  Rake::Task[:rspec].invoke('junit')
end

task default: %i[test rubocop_default]
task styles: :rubocop_default
task style_progress: :rubocop_progress
