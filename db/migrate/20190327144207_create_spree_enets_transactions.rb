class CreateSpreeEnetsTransactions < ActiveRecord::Migration[5.2]
  def change
    create_table :spree_enets_transactions do |t|
      t.string :nets_mid
      t.string :merchant_txn_ref
      t.string :merchant_txn_dtm
      t.string :payment_type
      t.string :currency_code
      t.string :nets_txn_ref
      t.string :payment_mode
      t.string :merchant_time_zone
      t.string :nets_txn_msg
      t.string :nets_amount_deducted
      t.string :stage_resp_code
      t.string :txn_rand
      t.string :bank_id
      t.string :bank_ref_code
      t.string :mask_pan
      t.string :bank_auth_id
      t.references :payment

      t.timestamps null: false
    end
  end
end
