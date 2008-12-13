class LibraryEvent < ActiveRecord::Base
  belongs_to :copy
  belongs_to :contact
end
