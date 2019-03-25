module Spree
  Order.class_eval do
    def to_enets
      OrderEnets.new(self).checkout
    end
  end
end
