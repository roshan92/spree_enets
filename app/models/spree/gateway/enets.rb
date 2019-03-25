module Spree
  class Gateway::Enets < Gateway

    preference :mode, :string, default: :sandbox
    preference :checkout_public_key, :string
    preference :checkout_secret_key, :string

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

    def setup
      Enets.config.mode = preferred_mode.to_sym
      Enets.config.checkout_public_key = preferred_checkout_public_key
      Enets.config.checkout_secret_key = preferred_checkout_secret_key
      Enets
    end
  end
end
