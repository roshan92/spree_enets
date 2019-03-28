module Spree
  class EnetsTransaction
    belongs_to :payment, class_name: 'Spree::Payment'
  end
end
