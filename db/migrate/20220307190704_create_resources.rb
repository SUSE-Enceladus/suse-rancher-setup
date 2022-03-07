class CreateResources < ActiveRecord::Migration[7.0]
  def change
    create_table :resources, id: :string do |t|
      t.string :type
      t.string :engine
      t.text :creation_attributes
      t.text :framework_raw_response

      t.timestamps
    end
  end
end
