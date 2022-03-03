$LOAD_PATH.push File.expand_path(__dir__, '..')
require "shirt_size/engine"

module ShirtSize
  def self.menu_entries
    [
      { caption: 'Cluster size', icon: 'photo_size_select_large', target: '/size/size/edit' }
    ]
  end
  # Your code goes here...
end
