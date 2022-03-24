class AddDurationToStep < ActiveRecord::Migration[7.0]
  def change
    add_column :steps, :duration, :integer, default: 1
  end
end
