$LOAD_PATH.push File.expand_path(__dir__, '..')
require "aws/engine"
require "cheetah"

module Aws
  def self.menu_entries
    [
      { caption: 'AWS CLI', icon: 'terminal', target: '/aws' }
    ]
  end
  # Your code goes here...
end
