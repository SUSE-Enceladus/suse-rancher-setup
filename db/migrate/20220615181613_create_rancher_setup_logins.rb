class CreateRancherSetupLogins < ActiveRecord::Migration[7.0]
  def change
    create_table :rancher_setup_logins do |t|

      t.timestamps
    end
  end
end
