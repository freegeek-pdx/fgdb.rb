class LibraryEvent < ActiveRecord::Base
  belongs_to :copy
  belongs_to :contact

  def self.kinds
    {
      :created => 1,
      :checked_out => 2,
      :renewed => 3,
      :checked_in => 4,
      :lost => 5,
      :found => 6,
    }
  end
end
