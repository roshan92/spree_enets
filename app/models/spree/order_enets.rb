module Spree
  class OrderEnets
    def initialize(order)
      @order = order
      @bill_address = @order.bill_address
      @ship_address = @order.ship_address
    end

    def checkout
      {
        total_amount: {
          currency: @order.currency,
          value: @order.order_total_after_store_credit.to_s,
          details: {
            shipping_fee: @order.shipment_total.to_s,
            discount: @order.promo_total.abs.to_s,
            tax: @order.tax_total.to_s
          }
        },
        buyer: buyer,
        items: items,
        request_reference_number: @order.number
      }
    end

    private

    def buyer
      {
        firstname: @bill_address.firstname,
        middle_name: "",
        lastname: @bill_address.lastname,
        contact: {
          phone: @bill_address.phone,
          email: @order.email
        },
        shipping_address: {
          line1: @ship_address.address1,
          line2: @ship_address.address2,
          city: @ship_address.city,
          state: @ship_address.state.to_s,
          zip_code: @ship_address.zipcode,
          country_code: @ship_address.country&.iso
        },
        billing_address: {
          line1: @bill_address.address1,
          line2: @bill_address.address2,
          city: @bill_address.city,
          state: @bill_address.state.to_s,
          zip_code: @bill_address.zipcode,
          country_code: @bill_address.country&.iso
        },
        ip_address: @order.user&.current_sign_in_ip
      }
    end

    def items
      @order.line_items.map do |li|
        {
          name: li.name,
          quantity: li.quantity.to_s,
          total_amount: {
            value: li.total.to_s,
            details: {
              tax: li.additional_tax_total.to_f,
              subtotal: li.subtotal.to_s}
            }
          }
      end
    end
  end
end
