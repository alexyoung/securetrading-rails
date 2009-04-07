require File.join(File.dirname(__FILE__), 'securetrading/xpay')
require File.join(File.dirname(__FILE__), 'securetrading/api')
require File.join(File.dirname(__FILE__), 'securetrading/settings')
require File.join(File.dirname(__FILE__), 'securetrading/payment')
require File.join(File.dirname(__FILE__), 'securetrading/subscription')

module Ecommerce::Merchants::SecureTrading
  API_VERSION = '3.51'
  API_DATE_FORMAT = '%Y-%m-%d'
end