class RrSet < ActiveRecord::Base
  has_many :rr_items

  def occurs? (date = Date.today )
    ret = false
    rr_items.each do |i|
      if i.occurs? date
        ret = true
      end
    end
    ret
  end
end
