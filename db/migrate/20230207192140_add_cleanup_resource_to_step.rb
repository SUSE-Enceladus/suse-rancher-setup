class AddCleanupResourceToStep < ActiveRecord::Migration[7.0]
  def change
    add_column :steps, :cleanup_resource, :boolean, default: true
  end
end
