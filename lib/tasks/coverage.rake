require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

desc 'Run all tests & specs for all workflows and aggregate coverage'
task :coverage do
  Rake::Task['vcr:clear_maps'].execute
  ENV['RAILS_ENV'] = 'test'
  ENV['LASSO_WORKFLOW'] = 'RancherOnEks'
  ENV['LASSO_ENGINES'] = 'AWS,ShirtSize,PreFlight,RancherOnEks,Helm'
  Rake::Task['test'].execute
  Rake::Task['spec'].execute

  ENV['RAILS_ENV'] = 'test'
  ENV['LASSO_WORKFLOW'] = 'RancherOnAks'
  ENV['LASSO_ENGINES'] = 'Azure,ShirtSize,PreFlight,RancherOnAks,Helm'
  Rake::Task['test'].execute
  Rake::Task['spec'].execute
end
