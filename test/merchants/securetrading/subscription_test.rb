ENV["RAILS_ENV"] = "test"

# Expand the path to environment so that Ruby does not load it multiple times
# File.expand_path can be removed if Ruby 1.9 is in use.
require File.expand_path(File.dirname(__FILE__) + "/../../../../../../config/environment")
require 'application'

require 'test/unit'

require File.dirname(__FILE__) + '/../../fake_tcp'

class SubscriptionTest < Test::Unit::TestCase
  include Ecommerce::Merchants::SecureTrading

  def test_create
    return
    
    #xpay_connection = FakeTCP.new(response_xml)
    #XPay.any_instance.stubs(:connect!).returns xpay_connection
    
    card = Ecommerce::Cards::VISA.new :number => '4111111111111111', 'expiry_date(2i)' => '09', 'expiry_date(1i)' => '09', :security_code => '123'
    order = Order.create :invoice_line => 'Tiktrac', :account_id => 1
    customer_info = CustomerInfo.new :first_name => 'Paul', :last_name => 'Smith', :name_prefix => 'Mr.', :middle_name => 'A.', :name_suffix => 'CEng.', :company => '', :street => '128B Oval Road', :city => 'Croydon', :state_prov => 'Surrey', :postal_code => 'CR0 6BL', :country_code => 'GBR', :phone => '02084061266', :email => 'alex@helicoid.net'
    
    Subscription.create customer_info, card, order, 99.99
    
    # Test the result of the content here
    #puts xpay_connection.content
  end
  
  def test_query
    XPay.any_instance.stubs(:connect!).returns FakeTCP.new(File.read(File.dirname(__FILE__) + '/../../fixtures/subscription_query_response.xml'))
    
    transaction_ids = Subscription.find :start_date => Date.today, :start_date => Date.today >> 1
    transaction_ids.each do |transaction_id|
      payment = Payment.new
      puts payment.settlement_query(transaction_id)
    end
  end
  
  def test_cancel
  end
  
  private
  
    def response_xml(result = 1)
      return <<-XML
<ResponseBlock Live="FALSE" Version="3.51"> 
 <Response Type="AUTH"> 
  <OperationResponse> 
   <TransactionReference>1-2-2432</TransactionReference> 
   <AuthCode>Auth Code:6284</AuthCode> 
   <Result>#{result}</Result>  
   <SettleStatus>0</SettleStatus> 
   <SecurityResponseSecurityCode>1</SecurityResponseSecurityCode> 
   <SecurityResponsePostCode>2</SecurityResponsePostCode> 
   <SecurityResponseAddress>4</SecurityResponseAddress> 
   <TransactionCompletedTimestamp>2000-10-04 
   23:24:02</TransactionCompletedTimestamp> 
   <TransactionVerifier>ljhLKH6H7fjhg+764J 
   ERsdFGhKJHGjhdsee09DSs+</TransactionVerifier> 
  </OperationResponse> 
  <Order> 
   <OrderReference>Order0001</OrderReference> 
   <OrderInformation>Test Order</OrderInformation> 
  </Order> 
 </Response> 
</ResponseBlock> 
      XML
    end
end
