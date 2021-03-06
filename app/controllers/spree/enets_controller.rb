require 'base64'
require 'openssl'

module Spree
  class EnetsController < StoreController
    before_action :load_order, except: [:server_callback]
    before_action :payment_method, only: [:index, :callback, :confirm]
    before_action :load_payment, only: [:cancel]
    protect_from_forgery only: :index

    def index
      success_url = payment_method.preferred_domain_name[0...-1].gsub("\n",'') + enets_confirm_path(params[:pid]).gsub("\n",'')
      callback_url = payment_method.preferred_domain_name[0...-1].gsub("\n",'') + enets_callback_path(params[:pid]).gsub("\n",'')
      server_callback_url = payment_method.preferred_domain_name[0...-1].gsub("\n",'') + enets_server_callback_path(params[:pid]).gsub("\n",'')
      cancel_url = payment_method.preferred_domain_name[0...-1].gsub("\n",'') + enets_cancel_path(params[:pid]).gsub("\n",'')

      txn_amt = @order.total
      if (!txn_amt.nil?)
        @txn_req = generate_payload(txn_amt, payment_method.preferred_umid, callback_url, server_callback_url)
        @hmac = generate_signature(@txn_req, payment_method.preferred_secret_key)
        @key_id = payment_method.preferred_public_key
      end
    end

    def server_callback
      @resp = Spree::EnetsTransaction.last
    end

    def callback
      if params[:message].nil?
        begin
          redirect_to products_path
        end
        return
      else
        response = JSON.parse(CGI.unescape(params[:message]))['msg']
        hmac = params[:hmac]
        key_id = params[:KeyId]
      end

      raise "Invalid Payment method" if payment_method.type != "Spree::Gateway::Enets"

      Spree::LogEntry.create({
        source: payment_method,
        details: params.to_yaml
      })

      raise "UMID mismatch" if response['netsMid'] != payment_method.preferred_umid

      # netsTxnStatus= 0 is successfully transaction. 1 is failed.
      if response['netsTxnStatus'] == '1'
        flash.alert = response['stageRespCode'] + ': ' + response['netsTxnMsg']
        @redirect_path = checkout_state_path(@order.state)
      end

      money = (@order.total.to_f*100).round
      if response['netsAmountDeducted'].to_i == money && response['netsTxnStatus'] == '0' && response['stageRespCode'].split('-').last == '00000'
        payment = @order.payments.create!({
          source_type: 'Spree::Gateway::Enets',
          amount: response['netsAmountDeducted'].to_f/100,
          payment_method: payment_method,
          response_code: response['stageRespCode'],
          avs_response: response['netsTxnMsg']
        })

        # NOTE: for has_one, use payment.create_enets_transaction!; for has_many, use payment.enets_transactions.create!
        payment.create_enets_transaction!(
          nets_mid: "#{response['netsMid']}",
          merchant_txn_ref: "#{response['merchantTxnRef']}",
          merchant_txn_dtm: "#{response['merchantTxnDtm']}",
          payment_type: "#{response['paymentType']}",
          currency_code: "#{response['currencyCode']}",
          nets_txn_ref: "#{response['netsTxnRef']}",
          payment_mode: "#{response['paymentMode']}",
          merchant_time_zone: "#{response['merchantTimeZone']}",
          nets_txn_msg: "#{response['netsTxnMsg']}",
          nets_amount_deducted: "#{response['netsAmountDeducted']}",
          stage_resp_code: "#{response['stageRespCode']}",
          txn_rand: "#{response['txnRand']}",
          bank_id: "#{response['bankId']}",
          bank_ref_code: "#{response['bankRefCode']}",
          mask_pan: "#{response['maskPan']}",
          bank_auth_id: "#{response['bankAuthId']}",
          payment_id: payment.id
        )

        payment.complete
        @order.next!

        if @order.complete?
          @current_order = nil
          flash.notice = Spree.t(:order_processed_successfully)
          @redirect_path = order_path(payment.order)
        else
          payment.state = "failed"
          payment.save
          @order.update_attributes(payment_state: "failed")
          flash.alert = "There was an error processing your payment"
          @redirect_path = checkout_state_path(payment.order.state)
        end
      end
    end

    def confirm
      raise "Invalid Payment method" if payment_method.type != "Spree::Gateway::Enets"

      if params[:message].nil?
        begin
          redirect_to products_path
        end
        return
      else
        response = JSON.parse(CGI.unescape(params[:message]))['msg']
      end

      raise "UMID mismatch" if response['netsMid'] != payment_method.preferred_umid

      if @order.payment_state != "paid"
        flash.alert = payment_method.preferred_failed_message
        begin
          redirect_to redirect_to checkout_state_path(@order.state) and return
        end
        return
      end

      flash.notice = payment_method.preferred_success_message
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

    def generate_payload(txnAmt, umid, callback_url, server_callback_url)
      time = Time.new
      merchantTxnRef = time.inspect[0..-7].tr('-','').tr(':','') + time.usec.to_s[0..-4]
      merchantTxnDtm = time.inspect[0..-7].tr('-','') + "." + time.usec.to_s[0..-4]

      txn_req = "{\"ss\":\"1\",\"msg\":{\"netsMid\":\""+umid+"\",\"tid\":\"\",\"submissionMode\":\"B\",\"txnAmount\":\""+(txnAmt.to_f*100).round.to_s+"\",\"merchantTxnRef\":\""+merchantTxnRef+"\",\"merchantTxnDtm\":\""+merchantTxnDtm+"\",\"paymentType\":\"SALE\",\"currencyCode\":\"SGD\",\"paymentMode\":\"CC\",\"merchantTimeZone\":\"+8:00\",\"b2sTxnEndURL\":\""+callback_url+"\",\"b2sTxnEndURLParam\":\"\",\"s2sTxnEndURL\":\""+server_callback_url+"\",\"s2sTxnEndURLParam\":\"\",\"clientType\":\"W\",\"supMsg\":\"\",\"netsMidIndicator\":\"U\",\"ipAddress\":\""+request.remote_ip+"\",\"language\":\"en\"}}"

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
