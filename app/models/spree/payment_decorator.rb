module Spree
  Payment.class_eval do
    has_one :enets_transaction, class_name: 'Spree::EnetsTransaction', dependent: :destroy
  end
end
