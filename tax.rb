module Ecommerce
  module Tax
    VAT = 15
    
    class << self
      def inc_vat(price)
        price + ((price / 100.0) * VAT)
      end
      
      def pays_vat?(location, vat_number = nil)
        # GB always pays VAT, EU countries only do when they supplied VAT, everyone else doesn't
        location == 'GB' or (Countries::in_eu?(location) and (vat_number.nil? or vat_number.strip.empty?))
      end
      
      def valid_vat_number?(location, vat_number)
        # TODO
        return true
      end
    end
  end
end
