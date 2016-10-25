class ContactTypesContact < ActiveRecord::Base
  belongs_to :contact
  belongs_to :contact_type
end
