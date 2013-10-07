class SpecSheetValue < ActiveRecord::Base
  belongs_to :spec_sheet
  belongs_to :spec_sheet_question
  before_save :remove_nonprintables_from_value
  validates_presence_of :value

  def remove_nonprintables_from_value
    if value && !value.blank?
      self.value = self.value.gsub(/[^\p{Print}]+/, " ")
      self.value = "<non-printable-characters>" if value.blank?
    end
  end

  def title
    self.spec_sheet_question.name.titleize
  end
end
