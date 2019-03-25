module Spree
  class EnetsController < StoreController
    before_action :load_order
    before_action :setup_paymaya, only: :pay
    before_action :verify_paymaya, only: :success
    before_action :load_payment, only: %i[success cancel failure]

    def pay
      @payment = @order.payments
                       .create!(amount: @order.total, payment_method: payment_method)
      @payment.started_processing!

      callback_urls = {
        success: paymaya_success_url(id: encrypted_paymaya_id, pid: @payment.number),
        failure: paymaya_failure_url(id: encrypted_paymaya_id, pid: @payment.number),
        cancel: paymaya_cancel_url(id: encrypted_paymaya_id, pid: @payment.number)
      }

      valid_checkout = @order.to_paymaya.merge(redirect_url: callback_urls)

      checkout = Paymaya::Checkout::Checkout.create valid_checkout

      redirect_to(checkout[:redirect_url]) && return
    rescue Exception => e
      Rails.logger.error e.message
      @payment.failure!

      flash[:error] = Spree.t(:paymaya_invalid)
      redirect_to(:back) && return
    end

    def success
      @payment.complete
      @payment.order.next!

      if @payment.order.complete?
        flash.notice = Spree.t(:order_processed_successfully)
        flash[:order_completed] = true
        session[:order_id] = nil
        redirect_to order_path(@payment.order)
      else
        redirect_to checkout_state_path(@payment.order.state)
      end
    end

    def cancel
      @payment.failure!
      flash[:error] = Spree.t(:payment_processing_failed)
      redirect_to checkout_state_path(@order.state)
    end

    def failure
      @payment.failure!
      flash[:error] = Spree.t(:payment_processing_failed)
      redirect_to checkout_state_path(@order.state)
    end

    def setup_paymaya
      payment_method.setup
    end

    private

    def load_order
      @order = current_order || raise(ActiveRecord::RecordNotFound)
    end

    def load_payment
      @payment = Spree::Payment.find_by(number: params['pid']) || raise(ActiveRecord::RecordNotFound)
    end

    def encrypted_paymaya_id
      secret = Rails.application.secrets.secret_key_base
      Rails.application.message_verifier(secret).generate(@order.number)
    end

    def payment_method
      PaymentMethod.find(params[:pid])
    end

    def verify_paymaya
      Rails.application.message_verifier(
        Rails.application.secrets.secret_key_base
      ).verify(params[:id])
    rescue StandardError
      redirect_to checkout_state_path(@order.state)
    end
  end
end
