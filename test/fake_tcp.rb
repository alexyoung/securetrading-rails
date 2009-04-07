class FakeTCP
  attr_reader :content
  
  def initialize(returns)
    @returns = returns
    @content = nil
  end
  
  def read
    # Returns XML
    @returns
  end
  
  def write(content)
    @content = content
  end
  
  def close
  end
end
