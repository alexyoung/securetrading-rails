module Ecommerce::Cards
  def self.new(options)
    ('Ecommerce::Cards::' + options[:type]).constantize.new(options)
  end
end

class Ecommerce::Cards::Base
  include Ecommerce::ActiveRecordBridge
  
  def type ; card_name ; end
  def attributes ; @attributes ; end
  
  def self.format_number(number)
    number.gsub(/[ -]/, '')
  end
  
  class ExpiryDate
    attr_accessor :month, :year, :day
    
    def initialize(month, year)
      @month = month.to_i
      @year = year.to_i
      @day = nil
    end
    
    def to_s
      sprintf '%02d/%02d', @month, @year
    end

    # Compatibility with the form helpers
    def change(options)
      date_time.change options
    end
    
    def date_time
      DateTime.new @year, @month
    end
    
    def expired?
      Time.now > (Time.mktime(@year, @month) + 1.month)
    end
  end
  
  def initialize(options = {})
    options[:number] = self.class.format_number(options[:number])
    @attributes = options
  end
  
  def validate
    errors.add 'expiry_date', 'has expired' if expired?
    errors.add 'number', 'is not a valid credit card number' unless Ecommerce::Cards::Base.valid_number? @attributes[:number]
    errors.add 'security_code', 'is required' unless @attributes[:security_code]
  end
  
  def to_xml
    xml = <<-XML
  <PaymentMethod>
   <CreditCard>
    <Type>#{card_name}</Type>
    <Number>#{@attributes[:number]}</Number>
    <Issue>#{@attributes[:issue]}</Issue>
    <ExpiryDate>#{expiry_date.to_s}</ExpiryDate>
    <StartDate>#{start_date.to_s}</StartDate>
    <SecurityCode>#{@attributes[:security_code]}</SecurityCode>
   </CreditCard>
  </PaymentMethod>
    XML
  end
  
  def expired?
    expiry_date.expired?
  end
  
  def expiry_date
    ExpiryDate.new @attributes['expiry_date(2i)'], @attributes['expiry_date(1i)']
  end
  
  def start_date
    if @attributes['start_date(2i)'] and @attributes['start_date(2i)'].to_i > 0 and @attributes['start_date(1i)'].to_i > 0
      ExpiryDate.new @attributes['start_date(2i)'], @attributes['start_date(1i)']
    else
      nil
    end
  end
  
  def self.valid_number?(number)
    return false unless number.to_s.length >= 13
    
    sum = 0
    for i in 0..number.length
      weight = number[-1 * (i + 2), 1].to_i * (2 - (i % 2))
      sum += (weight < 10) ? weight : weight - 9
    end
    
    (number[-1,1].to_i == (10 - sum % 10) % 10)
  end
end