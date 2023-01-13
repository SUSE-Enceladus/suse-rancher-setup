class AddViewDataToPreFlightCheck < ActiveRecord::Migration[7.0]
  def change
    add_column :pre_flight_checks, :view_data, :text
  end
end
