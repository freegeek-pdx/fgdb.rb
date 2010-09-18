class TonyChecksum
  def self.new_from_result(val)
    new({:result => val})
  end

  def self.new_from_checksum(val)
    new({:checksum => val})
  end

  def initialize(hash)
    @checksum = hash[:checksum]
    @result = hash[:result]
    @checksum = @checksum.to_s.downcase if @checksum
    @result = @result.to_s if @result
    @checkbit = nil
  end

  def checksum
    @checksum ||= _checksum
  end

  def result
    @result||= _result
  end

  def checkbit
    @checkbit ||= _checkbit
  end

  def _checkbit
    result
    checksum
    @checkbit
  end

  def _result
    arr = @checksum.scan(/./)
    @checkbit = arr.pop
    hex = arr.join("")
    result = hex.to_i(16).to_s
    raise Exception if checkbit != self.class.new_from_result(result).checkbit
    return result
  end

  def _checksum
    hex = @result.to_i.to_s(16)
    @checkbit = @result.to_i.to_s(2).scan(/./).inject(0){|t,x| t+=x.to_i}.to_s(16).scan(/./).last
    hex += @checkbit
    return hex
  end
end
