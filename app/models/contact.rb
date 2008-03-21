class Contact < ActiveRecord::Base
  :has_many reports
  def display_name #compatible with fgdb.rb
    "%s %s %s" % [self.first_name, self.middle_name, self.surname]
  end
end
