module Ecommerce::Merchants::SecureTrading
  class XPay
    # XPay XML responses are wrapped with this class
    class Response
      attr_reader :xml
      
      def initialize(xml)
        @xml = REXML::Document.new xml
      end
      
      def error?
        @xml.root.get_elements('Response/OperationResponse/Result').first.text == '0'
      end
      
      def success?
        @xml.root.get_elements('Response/OperationResponse/Result').first.text == '1'
      end
      
      def declined?
        @xml.root.get_elements('Response/OperationResponse/Result').first.text == '2'
      end
      
      def transaction_reference
        @xml.root.get_elements('Response/OperationResponse/TransactionReference').first.text
      end
      
      def to_xml
        @xml.to_s
      end
      
      def to_s
        if success?
          'The transaction was processed successfully.'
        elsif declined?
          'The transaction was declined by the card issuer.'
        else
          begin
            translate_error @xml.root.get_elements('Response/OperationResponse/Message').first.text
          rescue Exception
            Notifier.deliver_error_email("An error occurred processing a transaction:\n\n#{@xml.to_s}")
          end
        end
      end
      
      private
      
        def method_missing(sym, *attributes)
          element = @xml.root.get_elements("Response/OperationResponse/#{sym.to_s}")
          
          if element.first
            element.first.text
          else
            raise Ecommerce::MerchantInvalidRequest.new("Unable to find element #{element}")
          end
        end
        
        def translate_error(message)
          case message.match(/\((\d+)\)/)[1].to_i
            when 100, 101, 3000, 3010, 3330, 3350, 5000:
              raise Ecommerce::MerchantConnectionError.new(message)
            when 1000, 1100, 2100, 3100:
              raise Ecommerce::MerchantConfigurationError.new(message)
            when 2500:
              raise Ecommerce::MerchantInvalidRequest.new(message)
          end
        end
    end
    
    def initialize
      @connection = connect!
    end
    
    # Sends XML to XPay
    def send(*attributes)
      request_type = attributes.shift
      generated_xml = generate_xml(request_type, attributes.first)
      @connection.write generated_xml
      response = @connection.read
      @connection.close
      
      Response.new response
    end
    
    private
      # Connect to the XPay daemon
      def connect!
        TCPsocket.open 'localhost', 5000
      rescue Errno::ECONNREFUSED
        raise Ecommerce::MerchantConnectionError
      end
      
      def generate_xml(request_type, blocks = [])
        x = Builder::XmlMarkup.new :indent => 2
        blocks.compact!

        x.RequestBlock('Version' => API_VERSION) do
          x.Request('Type' => request_type) do |request|
            blocks.each do |block|
              xml = block.kind_of?(String) ? block : block.to_xml
              request << xml
            end
          end
        
          x.Certificate Settings.certificate
        end
      end
  end
end