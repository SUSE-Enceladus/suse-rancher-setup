$LOAD_PATH.push File.expand_path(__dir__, '..')
require "rancher_on_eks/engine"

module RancherOnEks
  def self.menu_entries
    [
      { caption: 'Deploy', icon: 'deploy', target: '/deploy/steps'}
    ]
  end
end
