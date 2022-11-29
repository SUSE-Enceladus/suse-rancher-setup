$LOAD_PATH.push File.expand_path(__dir__, '..')
require "azure/engine"

module Azure
  def self.menu_entries
    [
      { caption: 'Azure Login', icon: 'badge', target: '/azure/login/edit' },
      { caption: 'Azure Location', icon: 'location_on', target: '/azure/region/edit' }
    ]
  end
end
