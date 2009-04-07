SECURE_TRADING_OPTIONS = {}

module Ecommerce
  # This exception should be used to handle payment gateway timeouts in the merchant API code.
  class MerchantConnectionError < Exception ; end
  
  # The following exceptions should be caught in the application code.
  class MerchantConfigurationError < Exception ; end
  class MerchantInvalidRequest < Exception ; end
  
  module Cards
    class InvalidCard < Exception ; end
  end
  
  module Merchants
    class MerchantResponse
      attr_accessor :transaction, :success, :declined, :customer_details, :transaction_reference

      def success? ; @success == true ; end
      def declined? ; @declined == true ; end
      
      # Transaction is a copy of the transaction data.  This could be used later
      # with another instance of a merchant.  For example, repeat payment processing
      # might use this data.
      #
      # Customer details is XML that can be used by repeat payments
      #
      # Success determines of the transaction was successful.
      #
      # Text is the human readable text detailing the response.
      #
      def initialize(options = {})
        @transaction = options[:transaction]
        @success = options[:success]
        @declined = options[:declined]
        @text = options[:text]
        @customer_details = options[:customer_details]
        @transaction_reference = options[:transaction_reference]
      end
    end
  end
  
  # Use this for objects to work in forms.  include it, then provide an
  # attributes method that returns the object's attribute hash, and a
  # validate array.
  module ActiveRecordBridge
    def self.included(base)
      base.class_eval do
        def self.human_attribute_name(attribute) ; attribute.to_s.titlecase ; end
      end
    end
  
    def errors
      @errors ||= ActiveRecord::Errors.new(self)
    end
  
    def valid?
      errors.clear
      validate
      errors.empty?
    end
  
    private
  
      def method_missing(sym, *args)
        if attributes.has_key? sym
          attributes[sym]
        else
          raise
        end
      end
  end
end