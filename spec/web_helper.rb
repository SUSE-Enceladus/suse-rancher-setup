require 'rails_helper'
require 'capybara/rspec'
require 'digest'

def t(key, **args)
  I18n.translate!(key, **args).split("\n").first
end

def select_value(value, from:)
  within("##{from}") do
    find("option[value='#{value}']").select_option
  end
end

Capybara.configure do |config|
  config.automatic_label_click = true
end

puts("web_helper loaded")
