class Vacation < ActiveRecord::Base
  belongs_to :worker

  def name
    effective_date.strftime("%a, %b %d, %Y") + ' to ' + ineffective_date.strftime("%a, %b %d, %Y")
  end

end
