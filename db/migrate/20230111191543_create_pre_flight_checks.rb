class CreatePreFlightChecks < ActiveRecord::Migration[7.0]
  def change
    create_table :pre_flight_checks do |t|
      t.string :name
      t.boolean :passed
      t.string :job
      t.datetime :job_submitted_at
      t.datetime :job_completed_at

      t.timestamps
    end
  end
end
