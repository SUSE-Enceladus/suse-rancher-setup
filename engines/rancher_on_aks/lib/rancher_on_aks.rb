$LOAD_PATH.push File.expand_path(__dir__, '..')
require "rancher_on_aks/engine"

module RancherOnAks
  def self.menu_entries
    [
      { caption: 'Next Steps', icon: 'enhancement', target: '/deploy/wrapup'}
    ]
  end
end