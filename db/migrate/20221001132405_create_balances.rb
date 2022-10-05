class CreateBalances < ActiveRecord::Migration[7.0]
  def change
    create_table :balances do |t|
      t.integer :amount, default: 0
      t.string :owner
      t.timestamps
    end
  end
end
