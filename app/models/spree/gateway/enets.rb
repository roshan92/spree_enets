module Spree
  class Gateway::Enets < Gateway

    preference :umid, :string
    preference :public_key, :string
    preference :secret_key, :string
    preference :domain_name, :string, default: 'http://localhost:3000/'
    preference :image_url, :string, default: 'https://epayments.developer-ingenico.com/global/images/content/payment-products/enets/enets-logo.jpg'

    def provider_class
      Enets
    end

    def method_type
      'enets'
    end

    def auto_capture?
      true
    end

    def source_required?
      false
    end

    def purchase(amount, source, options = {})
      ActiveMerchant::Billing::Response.new(true, 'eNETS Success', {},{})
    end
  end
end
