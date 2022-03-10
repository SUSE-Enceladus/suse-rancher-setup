$LOAD_PATH.push File.expand_path(__dir__, '..')
require "aws/engine"

module Aws
  def self.menu_entries
    [
      { caption: 'AWS Credentials', icon: 'manage_accounts', target: '/aws/credential/edit' },
      { caption: 'AWS Region', icon: 'location_on', target: '/aws/region/edit' },
    ]
  end
end
