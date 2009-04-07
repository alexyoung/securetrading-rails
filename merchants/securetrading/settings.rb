module Ecommerce::Merchants::SecureTrading
  class Settings
    @@currency = 'GBP'
    @@site_reference = ''
    @@certificate = ''
    
    cattr_accessor :currency, :site_reference, :certificate
  end
end