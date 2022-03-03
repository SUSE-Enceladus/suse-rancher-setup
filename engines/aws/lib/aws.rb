$LOAD_PATH.push File.expand_path(__dir__, '..')
require "aws/engine"
require "cheetah"

module Aws
  def self.menu_entries
    [
      { caption: 'AWS Credentials', icon: 'manage_accounts', target: '/aws/credential/edit' },
      { caption: 'AWS CLI', icon: 'terminal', target: '/aws/cli/new' }
    ]
  end
  # Your code goes here...
end
