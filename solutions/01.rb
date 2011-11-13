class Array
  def to_hash
    Hash[*self.flatten(1)]
  end
  
  def index_by(&block)
    map(&block).zip(self).to_hash
  end
  
  def subarray_count(subarray)
    count = 0
    (0...size).each { |idx| count +=1 if slice(idx, subarray.size) == subarray }
    count
  end
  
  def occurences_count
    new_hash = Hash.new(0)
    each { |el| new_hash[el] += 1 }
    new_hash
  end
end