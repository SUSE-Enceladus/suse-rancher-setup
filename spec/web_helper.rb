require 'rails_helper'
require 'capybara/rspec'
require 'digest'

def t(key, **args)
  I18n.translate!(key, **args).split("\n").first
end

Capybara.configure do |config|
  config.automatic_label_click = true
end

puts("web_helper loaded")
