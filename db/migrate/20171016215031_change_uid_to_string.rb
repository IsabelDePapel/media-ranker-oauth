class ChangeUidToString < ActiveRecord::Migration[5.0]
  def change
    change_column :users, :uid, :string
  end
end
