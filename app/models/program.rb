class Program < ActiveRecord::Base
  def display_name
    description.downcase
  end
end
