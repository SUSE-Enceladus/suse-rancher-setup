require 'simplecov-json'

SimpleCov.start 'rails' do
  enable_coverage :branch

  add_filter '/test'
  add_filter '/spec'
  add_filter 'config'

  formatter SimpleCov::Formatter::MultiFormatter.new([
    SimpleCov::Formatter::JSONFormatter,
    SimpleCov::Formatter::HTMLFormatter
  ])

  SimpleCov.minimum_coverage 0
end
