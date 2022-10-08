def _deep_symbolize_keys!(object)
  case object
  when Hash
    object.keys.each do |key|
      value = object.delete(key)
      object[(key.to_sym rescue key)] = _deep_symbolize_keys!(value)
    end
    object
  when Array
    object.map! { |e| _deep_symbolize_keys!(e) }
  else
    object
  end
end

class Integer
  N_BYTES = [42].pack('i').size
  N_BITS = N_BYTES * 8
  MAX = 2 ** (N_BITS - 2) - 1
  MIN = -MAX - 1

  def commify
    to_s.gsub(/(\d)(?=(\d{3})+(?:\.|\z))/,'\1,')
  end
end

class Float
  def commify
    whole, frac = to_s.split('.')
    [whole.to_i.commify, frac].join('.')
  end
end

class String
  def hash
    sum
  end
end

class Date
  def inspect
    %Q[Date.parse(#{to_s.inspect})]
  end
end

class Time
  def inspect
    %Q[Time.parse(#{to_s.inspect})]
  end
end
