require File.dirname(__FILE__) + '/test_helper'

class CardTest < Test::Unit::TestCase
  def test_card_expiry_format
    expiry = Ecommerce::Cards::Base::ExpiryDate.new 1, 7
    assert_equal '01/07', expiry.to_s
    
    expiry = Ecommerce::Cards::Base::ExpiryDate.new 11, 7
    assert_equal '11/07', expiry.to_s
  end
  
  def test_card_expiry_expired?
    expiry = Ecommerce::Cards::Base::ExpiryDate.new 11, 7
    assert !expiry.expired?
    
    expiry = Ecommerce::Cards::Base::ExpiryDate.new 1, 7
    assert expiry.expired?
    
    expiry = Ecommerce::Cards::Base::ExpiryDate.new 1, 1
    assert expiry.expired?
  end
end