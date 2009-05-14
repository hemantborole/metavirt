class Hash
  # Return a hash of all the elements where the block evaluates to true
  def choose(&block)
    Hash[*self.select(&block).inject([]){|res,(k,v)| res << k << v}]
  end
  
  def create(keys, values)
    self[*keys.zip(values).flatten]
  end
  
  def symbolize_keys
    dup.stringify_keys!
  end
  
  # Converts all of the keys to strings
  def symbolize_keys!
    keys.each{|k| 
      v = delete(k)
      self[k.to_sym] = v
      v.symbolize_keys! if v.is_a?(Hash)
      v.each{|p| p.symbolize_keys! if p.is_a?(Hash)} if v.is_a?(Array)
    }
    self
  end
  
  def method_missing(sym, *args, &block)
    if has_key?(sym)
      fetch(sym)
    elsif has_key?(sym.to_s)
      fetch(sym.to_s)
    else
      super
    end
  end
end