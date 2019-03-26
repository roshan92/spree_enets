require 'Base64'
require 'openssl'

module Spree
  class EnetsController < StoreController
    before_action :load_order
    before_action :payment_method, only: [:index]
    before_action :load_payment, only: [:cancel]
    protect_from_forgery only: :index

    def index
        # payment_method = Spree::PaymentMethod.find_by(id: payment_method_id)
        # success_url = payment_method.preferred_domain_name[0...-1].gsub("\n",'') + paysera_confirm_path(payment_method_id).gsub("\n",'')
        # callback_url = payment_method.preferred_domain_name[0...-1].gsub("\n",'') + paysera_callback_path(payment_method_id).gsub("\n",'')
        # cancel_url = payment_method.preferred_domain_name[0...-1].gsub("\n",'') + paysera_cancel_path(payment_method_id).gsub("\n",'')

        # order = current_order || raise(ActiveRecord::RecordNotFound)
        # amount = @order.total * 100
        # payment_method.preferred_test_mode ? test_value = 1 : test_value = 0
        # paytext_value = payment_method.preferred_message_text.present? ? payment_method.preferred_message_text : 'Payment'

        txn_amt = @order.total

        if (!txn_amt.nil?)
          @txn_req = generate_payload(txn_amt, payment_method.preferred_umid)
          @hmac = generate_signature(@txn_req, payment_method.preferred_secret_key)
          @key_id = payment_method.preferred_public_key

          render 'index'

          # @payment = @order.payments.create!(amount: @order.total, payment_method: payment_method)
          # @payment.started_processing!
        end

        # begin
        #   redirect_to url
        # end
    end

    def callback
        if params[:data].nil?
            begin
            redirect_to products_path
            end
            return
        end
        payment_method = Spree::PaymentMethod.find_by(id: params[:payment_method_id])
        raise send_error("invalid payment method") if payment_method.type != "Spree::Gateway::Enets"
        Spree::LogEntry.create({
            source: payment_method,
            details: params.to_yaml
        })
        response = parse(params)
        if response[:projectid].to_i != payment_method.preferred_project_id
            render plain: 'Error: project id does not match'
            return
        end
        order = Spree::Order.find_by(number: response[:orderid])

        money = order.total * 100
        if response[:payamount].to_i >= money.to_i
            if response[:payamount].to_i > money.to_i
                payment = order.payments.create!({
                    source_type: 'Spree::Gateway::Enets',
                    amount: response[:payamount].to_d/100,
                    payment_method: payment_method
                })
                payment.complete
                order.next

                if order.payment_state == "paid"
                    render plain: 'OK payment amount is greater than order total'
                    return
                else
                    render plain: 'Error processing payment'
                    return
                end
            else
                payment = order.payments.create!({
                    source_type: 'Spree::Gateway::Enets',
                    amount: response[:payamount].to_d/100,
                    payment_method: payment_method
                })
                payment.complete
                order.next

                if order.payment_state == "paid"
                    render plain: 'OK'
                    return
                else
                    render plain: 'Error processing payment'
                    return
                end
            end
        else
            render plain: 'Error: bad order amount'
            return
        end


    end

    def confirm
        payment_method = Spree::PaymentMethod.find_by(id: params[:payment_method_id])
        raise send_error("invalid payment method") if payment_method.type != "Spree::Gateway::Enets"
        if params[:data].nil?
            begin
            redirect_to products_path
            end
            return
        end
        response = parse(params)
        raise send_error("'projectid' mismatch") if response[:projectid].to_i != payment_method.preferred_project_id
        order = Spree::Order.find_by(number: response[:orderid])

        if order.payment_state != "paid"
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
