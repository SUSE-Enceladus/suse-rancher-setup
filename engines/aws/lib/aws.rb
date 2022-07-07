$LOAD_PATH.push File.expand_path(__dir__, '..')
require "aws/engine"

module AWS
  def self.menu_entries
    [
      { caption: 'AWS Region', icon: 'location_on', target: '/aws/region/edit' },
    ]
  end
end
