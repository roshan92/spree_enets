require 'Base64'
require 'openssl'

module Spree
  class EnetsController < StoreController
    before_action :load_order
    before_action :payment_method, only: [:pay]
    before_action :load_payment, only: %i[success cancel failure]

    def pay
      txn_amt = @order.total
      if (!txn_amt.nil?)
        @txn_req = generate_payload(txn_amt, payment_method.preferred_umid)
        @hmac = generate_signature(txn_req, payment_method.preferred_secret_key)
        @key_id = payment_method.preferred_public_key

        # @payment = @order.payments.create!(amount: @order.total, payment_method: payment_method)
        # @payment.started_processing!

        respond_to do |format|
          format.js
        end
      end

    rescue Exception => e
      Rails.logger.error e.message
      @payment.failure!

      flash[:error] = Spree.t(:enets_invalid)
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

    private

    def load_order
      @order = current_order || raise(ActiveRecord::RecordNotFound)
    end

    def load_payment
      @payment = Spree::Payment.find_by(number: params['pid']) || raise(ActiveRecord::RecordNotFound)
    end

    def payment_method
      Spree::PaymentMethod.find(params[:pid])
    end

    def generate_payload(txnAmt, umid)
      time = Time.new
      merchantTxnRef = time.inspect[0..-7].tr('-','').tr(':','') + time.usec.to_s[0..-4]
      merchantTxnDtm = time.inspect[0..-7].tr('-','') + "." + time.usec.to_s[0..-4]

      txn_req = "{\"ss\":\"1\",\"msg\":{\"netsMid\":\""+umid+"\",\"tid\":\"\",\"submissionMode\":\"B\",\"txnAmount\":\""+txnAmt.to_s+"\",\"merchantTxnRef\":\""+merchantTxnRef+"\",\"merchantTxnDtm\":\""+merchantTxnDtm+"\",\"paymentType\":\"SALE\",\"currencyCode\":\"SGD\",\"paymentMode\":\"\",\"merchantTimeZone\":\"+8:00\",\"b2sTxnEndURL\":\"https://httpbin.org/post\",\"b2sTxnEndURLParam\":\"\",\"s2sTxnEndURL\":\"https://sit2.enets.sg/MerchantApp/rest/s2sTxnEnd\",\"s2sTxnEndURLParam\":\"\",\"clientType\":\"W\",\"supMsg\":\"\",\"netsMidIndicator\":\"U\",\"ipAddress\":\"127.0.0.1\",\"language\":\"en\"}}"

      return txn_req
    end

    def generate_signature(txn_req, secret_key)
      concat_txn_req_secret_key = txn_req+secret_key
      hash = Digest::SHA256.digest(concat_txn_req_secret_key.encode('utf-8'))
      encoded = Base64.encode64(hash)
      return encoded.to_s
    end
  end
end
