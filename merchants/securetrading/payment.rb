module Ecommerce::Merchants::SecureTrading
  class Payment
    def initialize(options = {})
      @parent_response = options[:parent_response]
      @transaction_reference = options[:transaction_reference]
    end
    
    class << self
      def create(customer_info, card, order, amount, settlement_day = 1)
        raise Ecommerce::Cards::InvalidCard unless card.valid?
    
        amount = (amount * 100).to_i
        operation = Operations::Auth.new 'Amount' => amount, 'SettlementDay' => settlement_day
        xpay = XPay.new
    
        retries = 0
        begin
          response = xpay.send 'AUTH', [operation, customer_info, card, order]
      
          Ecommerce::Merchants::MerchantResponse.new response.to_xml, customer_info.to_xml, response.success?, response.declined?, response.to_s
        rescue Ecommerce::MerchantConnectionError
          retries += 1
          retry if retries < 3
          raise
        end
      end
    end

    def repeat(customer_xml, order, amount)
      amount = (amount * 100).to_i
  
      xpay = XPay.new
      operation = Operations::Auth.new 'Amount' => amount, 'SettlementDay' => 1
      card = RepeatPaymentMethod.new @parent_response

      retries = 0
      begin
        response = xpay.send 'CONTINUOUSAUTH', [operation, customer_xml, card, order]
        Ecommerce::Merchants::MerchantResponse.new response.to_xml, customer_xml, response.success?, response.declined?, response.to_s
      rescue Ecommerce::MerchantConnectionError
        retries += 1
        retry if retries < 3
        raise
      end
    end

    def auth_reversal(customer_xml, order, amount)
      amount = (amount * 100).to_i

      xpay = XPay.new
      operation = Operations::Auth.new 'Amount' => amount, 'SettlementDay' => 1
      card = RepeatPaymentMethod.new @parent_response

      retries = 0
      begin
        response = xpay.send 'AUTHREVERSAL', [operation, customer_xml, card, order]
        Ecommerce::Merchants::MerchantResponse.new response.to_xml, customer_xml, response.success?, response.to_s
      rescue Ecommerce::MerchantConnectionError
        retries += 1
        retry if retries < 3
        raise
      end
    end

    def settlement_query
      xpay = XPay.new
      @transaction_reference = Operations::Settlement.get_transaction_reference(@parent_response) unless @transaction_reference
      operation = Operations::Settlement.new @transaction_reference

      retries = 0
      begin
        response = xpay.send 'SETTLEMENT', [operation]

        if response.error?
          return 'Error'
        elsif response.declined?
          return 'Declined'
        else
          case response.SettleStatus
          when '0', '1', '10'
            return 'Pending'
          when '100'
            return 'Settled'
          else
            return 'Declined'
          end
        end

      rescue Ecommerce::MerchantConnectionError
        retries += 1
        retry if retries < 3
        raise
      end
    end
  end
end