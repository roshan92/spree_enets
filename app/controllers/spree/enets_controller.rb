require 'Base64'
require 'openssl'

module Spree
  class EnetsController < StoreController
    before_action :load_order
    before_action :payment_method, only: [:index, :callback, :confirm]
    before_action :load_payment, only: [:cancel]
    protect_from_forgery only: :index

    def index
      success_url = payment_method.preferred_domain_name[0...-1].gsub("\n",'') + enets_confirm_path(params[:pid]).gsub("\n",'')
      callback_url = payment_method.preferred_domain_name[0...-1].gsub("\n",'') + enets_callback_path(params[:pid]).gsub("\n",'')
      cancel_url = payment_method.preferred_domain_name[0...-1].gsub("\n",'') + enets_cancel_path(params[:pid]).gsub("\n",'')

      txn_amt = @order.total

      if (!txn_amt.nil?)
        @txn_req = generate_payload(txn_amt, payment_method.preferred_umid, callback_url)
        @hmac = generate_signature(@txn_req, payment_method.preferred_secret_key)
        @key_id = payment_method.preferred_public_key
      end
    end

    def callback
      if params[:message].nil?
        begin
          redirect_to products_path
        end
        return
      else
        response = JSON.parse(CGI.unescape(params[:message]))
        hmac = params[:hmac]
        key_id = params[:KeyId]
      end

      raise send_error("UMID mismatch") if response[:netsMid] != payment_method.preferred_umid
      raise send_error("invalid payment method") if payment_method.type != "Spree::Gateway::Enets"

      Spree::LogEntry.create({
          source: payment_method,
          details: params.to_yaml
      })

      # if hmac != @hmac
      #   render plain: 'Error: Fraud Transaction.'
      #   return
      # end
      # order = Spree::Order.find_by(number: response[:orderid])

      money = @order.total * 100
      if response[:netsAmountDeducted].to_i >= money.to_i
        if response[:payamount].to_i > money.to_i
          payment = @order.payments.create!({
              source_type: 'Spree::Gateway::Enets',
              amount: (response[:netsAmountDeducted].to_f/100).round,
              payment_method: payment_method
          })
          payment.complete
          @order.next

          if @order.payment_state == "paid"
            render plain: 'OK payment amount is greater than order total'
            return
          else
            render plain: 'Error processing payment'
            return
          end
        else
          payment = @order.payments.create!({
              source_type: 'Spree::Gateway::Enets',
              amount: (response[:netsAmountDeducted].to_f/100).round,
              payment_method: payment_method
          })
          payment.complete
          @order.next

          if @order.payment_state == "paid"
            render plain: 'Order completed. Payment Successfully!'
            return
          else
            render plain: 'Error processing payment'
            return
          end
        end
      else
        render plain: 'Error: Bad order amount'
        return
      end
    end

    def confirm
      raise send_error("invalid payment method") if payment_method.type != "Spree::Gateway::Enets"

      if params[:data].nil?
        begin
        redirect_to products_path
        end
        return
      else
        response = JSON.parse(CGI.unescape(params[:message]))
        hmac = params[:hmac]
        key_id = params[:KeyId]
      end

      raise send_error("UMID mismatch") if response[:netsMid] != payment_method.preferred_umid

      if @order.payment_state != "paid"
        flash.alert = Spree.t(:payment_processing_failed)
        begin
          redirect_to cart_path
        end
        return
      end

      flash.notice = Spree.t(:order_processed_successfully)
      begin
        redirect_to user_root_path
      end
      return
    end

    def cancel
      flash.notice = Spree.t(:order_canceled)
      begin
        redirect_to products_path
      end
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

    def generate_payload(txnAmt, umid, callback_url)
      time = Time.new
      merchantTxnRef = time.inspect[0..-7].tr('-','').tr(':','') + time.usec.to_s[0..-4]
      merchantTxnDtm = time.inspect[0..-7].tr('-','') + "." + time.usec.to_s[0..-4]

      txn_req = "{\"ss\":\"1\",\"msg\":{\"netsMid\":\""+umid+"\",\"tid\":\"\",\"submissionMode\":\"B\",\"txnAmount\":\""+(txnAmt.to_f*100).round.to_s+"\",\"merchantTxnRef\":\""+merchantTxnRef+"\",\"merchantTxnDtm\":\""+merchantTxnDtm+"\",\"paymentType\":\"SALE\",\"currencyCode\":\"SGD\",\"paymentMode\":\"\",\"merchantTimeZone\":\"+8:00\",\"b2sTxnEndURL\":\""+callback_url+"\",\"b2sTxnEndURLParam\":\"\",\"s2sTxnEndURL\":\"https://sit2.enets.sg/MerchantApp/rest/s2sTxnEnd\",\"s2sTxnEndURLParam\":\"\",\"clientType\":\"W\",\"supMsg\":\"\",\"netsMidIndicator\":\"U\",\"ipAddress\":\"127.0.0.1\",\"language\":\"en\"}}"

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
