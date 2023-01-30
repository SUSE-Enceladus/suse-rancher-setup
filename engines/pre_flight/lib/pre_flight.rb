$LOAD_PATH.push File.expand_path(__dir__, '..')
require "pre_flight/engine"

module PreFlight
  # pre-flight check should have it's menu entry loaded by the workflow,
  # immediately before deployment
  def self.menu_entries
    []
  end

  def self.menu_entry
    { caption: 'Pre-Flight Checks', icon: 'rule', target: '/preflight/checks' }
  end
end
