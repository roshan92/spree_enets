module Spree
  class Gateway::Enets < Gateway

    preference :umid, :string
    preference :public_key, :string
    preference :secret_key, :string
    preference :image_url, :string, default: 'https://epayments.developer-ingenico.com/global/images/content/payment-products/enets/enets-logo.jpg'

    def provider_class
      Enets
    end

    def method_type
      'enets'
    end

    def can_void?(payment)
      payment.state != 'void'
    end

    def actions
      %w{void}
    end

    def void(*args)
      ActiveMerchant::Billing::Response.new(true, "Void by admin user", {}, {})
    end

    def auto_capture?
      false
    end

    def source_required?
      false
    end

    def payment_profiles_supported?
      false
    end
  end
end
