module Spree
  class EnetsTransaction < Spree::Base
    belongs_to :payment, class_name: 'Spree::Payment'
  end
end
