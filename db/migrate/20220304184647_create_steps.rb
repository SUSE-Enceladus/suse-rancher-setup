class CreateSteps < ActiveRecord::Migration[7.0]
  def change
    create_table :steps do |t|
      t.integer :rank
      t.string :action
      t.string :resource_id
      t.datetime :started_at
      t.datetime :completed_at

      t.timestamps
    end

    add_index(:steps, :rank, unique: true)

  end
end
