module Ecommerce::Merchants::SecureTrading
  module SecureTradingXML
    def to_xml
      @type = self.class.name.split('::').last unless @type
      @attributes.to_xml :root => @type, :skip_instruct => true, :indent => 2, :skip_types => true
    end
  end
  
  class CustomerInfo
    include SecureTradingXML
    include Ecommerce::ActiveRecordBridge

    def attributes ; @original_attributes ; end

    # Takes a flat hash provided by a typical rails form and stores in the SecureTrading format
    def initialize(attributes = {})
      @defaults = HashWithIndifferentAccess.new :country => nil, :first_name => nil, :last_name => nil, :middle_name => nil, :street => nil, :postal_code => nil, :phone => nil, :email => nil, :city => nil, :state_prov => nil
      @original_attributes = @defaults.merge attributes
      @attributes = translate_flat_hash(attributes)
    end
    
    def validate
      errors.add 'first_name', 'is required' if attributes[:first_name].blank?
      errors.add 'last_name', 'is required' if attributes[:last_name].blank?
      errors.add 'street', 'is required' if attributes[:street].blank?
      errors.add 'postal_code', 'is required' if attributes[:postal_code].blank?
    end
    
    def translate_flat_hash(attributes)
      { :Postal => 
        {
          :Name => {
            :NamePrefix => attributes[:name_prefix].to_s,
            :FirstName => attributes[:first_name].to_s,
            :MiddleName => attributes[:middle_name].to_s,
            :LastName => attributes[:last_name].to_s,
            :NameSuffix => attributes[:name_suffix].to_s
          },
          
          :Company => attributes[:company].to_s,
          :Street => attributes[:street].to_s,
          :City => attributes[:city].to_s,
          :StateProv => attributes[:state_prov].to_s,
          :PostalCode => attributes[:postal_code].to_s,
          :CountryCode => attributes[:country_code].to_s
        },
        
        :Telecom => { :Phone => attributes[:phone].to_s },
        :Online => { :Email => attributes[:email].to_s }
      }
    end
  end
  
  class RepeatPaymentMethod
    include SecureTradingXML
    
    def initialize(parent_response)
      @type = 'PaymentMethod'
      @parent_response = REXML::Document.new parent_response
      
      @attributes = {
        :CreditCard => {
          :TransactionVerifier => transaction_verifier,
          :ParentTransactionReference => parent_transaction_reference
        }
      }
    end
    
    def transaction_verifier
      @parent_response.root.get_elements('Response/OperationResponse/TransactionVerifier').first.text
    end
    
    def parent_transaction_reference
      @parent_response.root.get_elements('Response/OperationResponse/TransactionReference').first.text
    end
  end
  
  # This one actually uses an active record table for tracking orders and creating unique order references
  class Order < ActiveRecord::Base
    def to_xml
      data = {}
      data['OrderReference'] = id
      data['OrderInformation'] = invoice_line
      data.to_xml :root => 'Order', :skip_instruct => true, :indent => 2, :skip_types => true
    end
  end

  module Operations
    class Auth
      include SecureTradingXML
      attr_accessor :type
      
      def initialize(attributes = {})
        @type = 'Operation'
        attributes['Currency'] = Settings.currency
        attributes['SiteReference'] = Settings.site_reference
        @attributes = attributes
      end
    end
    
    class Settlement
      include SecureTradingXML
      attr_accessor :type
      
      def self.get_transaction_reference(parent_response)
        REXML::Document.new(parent_response).root.get_elements('Response/OperationResponse/TransactionReference').first.text
      end
      
      def initialize(transaction_reference)
        @type = 'Operation'
        
        @attributes = {}
        @attributes['Currency'] = Settings.currency
        @attributes['TransactionReference'] = transaction_reference
        @attributes['SiteReference'] = Settings.site_reference
      end
    end
  end
end