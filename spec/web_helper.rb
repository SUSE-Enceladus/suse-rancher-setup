require 'rails_helper'
require 'capybara/rspec'
require 'digest'

def t(key, **args)
  I18n.translate!(key, **args).split("\n").first
end

Capybara.configure do |config|
  config.automatic_label_click = true
end

def cheetah_vcr(force_recording: false)
  allow(Cheetah).to receive(:run).and_wrap_original do |method, *args|
    cli_args = args.first
    fixture_dir = Rails.root.join('spec', 'vcr', cli_args.first)
    filename = Digest::MD5.hexdigest(cli_args.flatten.join(' '))
    fixture_path = fixture_dir.join(filename)
    FileUtils.mkdir_p(fixture_dir)
    puts("Using #{fixture_path} for args '#{cli_args.join(' ')}'") if ENV['DEBUG']
    if File.exists?(fixture_path) && !force_recording
      File.read(fixture_path)
    else
      puts("Writing #{fixture_path} from args '#{cli_args.join(' ')}'")
      stdout, stderr = method.call(*args)
      File.open(fixture_path, 'w') { |file| file.print(stdout) }
      [stdout, stderr]
    end
  end
end

puts("web_helper loaded")
