class Hash
  def self.symbolize_keys value
    return value if not value.is_a?(Hash)
    value.inject({}){|memo,(k,v)| memo[k.to_sym] = Hash.symbolize_keys(v); memo}
  end

  def symbolize_keys
    Hash.symbolize_keys self
  end
end

class Array
  def symbolize_keys
    map{|i| Hash.symbolize_keys i }
  end
end