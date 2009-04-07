module Ecommerce::Merchants::SecureTrading
  class Subscription
    def initialize(options = {})
      @parent_response = options[:parent_response]
      @transaction_reference = options[:transaction_reference]
      
      if @parent_response
        @transaction_reference = RepeatPaymentMethod.new(@parent_response).parent_transaction_reference
      end
    end
    
    class Transaction
      attr_reader :reference, :active, :parent_reference, :next_date
      
      def initialize(xml)
        @xml = xml
        
        parse unless @xml.nil?
      end
      
      def settle_status
        payment = Payment.new :transaction_reference => @reference unless @payment
        payment.settlement_query
      end
      
      def active?
        @active
      end
      
      def xml
        @xml.to_s
      end
      
      private
      
        def parse
          @xml = REXML::Document.new(@xml)
        
          @reference = if @xml.root.get_elements('ChildTransactionReference').first.text.nil? or @xml.root.get_elements('ChildTransactionReference').first.text == 'None'
            @xml.root.get_elements('ParentTransactionReference').first.text
          else
            @xml.root.get_elements('ChildTransactionReference').first.text
          end
          
          @active = @xml.root.get_elements('Active').first.text == '1' ? true : false
          @parent_reference = @xml.root.get_elements('ParentTransactionReference').first.text
          @next_date = @xml.root.get_elements('NextDate').first.text
        end
    end
    
    class << self
      # Create a new subscription
      def authorise(customer_info, card, order, amount, begin_date = (Date.today + 1), unit = 'Month', period = 1, settlement_day = 1, how_many = 999)
        raise Ecommerce::Cards::InvalidCard unless card.valid?

        amount = (amount * 100).to_i
        operation = Operations::Auth.new 'Amount' => amount, 'SettlementDay' => settlement_day, 'Unit' => unit, 'Period' => period, 'HowMany' => how_many, 'BeginDate' => begin_date.strftime(API_DATE_FORMAT)
        xpay = XPay.new

        retries = 0
        begin
          response = xpay.send 'SUBSCRIPTIONAUTH', [operation, customer_info, card, order]
          response
        rescue Ecommerce::MerchantConnectionError
          retries += 1
          retry if retries < 3
          raise
        end
      end
      
      def query(start_date, end_date = nil)
        end_date = start_date if end_date.nil?
        xpay = XPay.new

        operation = Operations::Auth.new 'StartDate' => start_date.strftime(API_DATE_FORMAT), 'EndDate' => end_date.strftime(API_DATE_FORMAT)
        response = xpay.send 'SUBSCRIPTIONQUERY', [operation]
        response.to_xml
      end
      
      def find(options = {})
        start_date = options[:start_date]
        end_date = options[:end_date]
        xml = query start_date, end_date
        
        transactions = REXML::Document.new(xml).root.get_elements('Response/OperationResponse/Subscription').collect do |subscription|
          Transaction.new subscription.to_s
        end
      end
    end
    
    # Cancel a subscription
    def cancel
      update :active => false
    end

    # This can be used to update the subscription's amount, card details or active status
    def update(options = {})
      card = options[:card]
      amount = (options[:amount] * 100).to_i if options.has_key?(:amount)
      active = options[:active] ? 1 : 0

      raise Ecommerce::Cards::InvalidCard unless card.nil? or card.valid?

      operation_options = {}
      operation_options['Amount'] = amount unless amount.nil?
      operation_options['ActiveFlag'] = (options[:active] ? 1 : 0) if options.has_key?(:active)
      operation_options['ParentTransactionReference'] = @transaction_reference

      operation = Operations::Auth.new operation_options
      xpay = XPay.new

      retries = 0
      begin
        xpay.send 'SUBSCRIPTIONUPDATE', [operation, card]
      rescue Ecommerce::MerchantConnectionError
        retries += 1
        retry if retries < 3
        raise
      end
    end
  end
end