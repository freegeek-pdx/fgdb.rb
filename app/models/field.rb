class Field < ActiveRecord::Base
  belongs_to :book
  acts_like_parent_is_xapian :parent => "book"
end
