class SpecSheet < ActiveRecord::Base
  include SystemHelper

  validates_presence_of :contact_id
  validates_presence_of :action_id
  validates_presence_of :type_id

  belongs_to :builder_task, :dependent => :destroy
  belongs_to :system
  belongs_to :type
  has_one :contract, :through => :system
  validates_associated :builder_task
  validates_associated :spec_sheet_values

  after_save :save_bt

  has_many :spec_sheet_values, :include => [:spec_sheet_question], :order => "spec_sheet_questions.position ASC"

  def pricing_hash
    @pricing_hash ||= begin
                        h = {}
                          h = self.parser.pricing_hash
                          h[:build_type] = self.type ? self.type.name : nil
                        self.spec_sheet_values.each do |x|
                               h[x.spec_sheet_question.name.underscore.to_sym] = x.value
                            end
                        # FIXME: underscore?
                        if h["dimm type".to_sym] && h["dimm type".to_sym].match(/FB[ -]?DIMM/i) && h[:memory_type] = "DDR2"
                          h[:memory_type] = "DDR2 FB-DIMM"
                        end
                          h
                        end
  end

  # is there already an inverse to Hash.to_a ?
  def r_hash_parse(arr)
    h = {}
    arr.each{|x,y|
      h[x] = y
    }
    h
  end

  def questions=(hash)
    r_hash_parse(hash).each do |k,v|
      tid = k.to_s.sub(/^id_/, "").to_i
      sv = self.spec_sheet_values.select{|x| x.spec_sheet_question_id == tid}.first || SpecSheetValue.new
      sv.spec_sheet_question_id = tid
      sv.value = v
      self.spec_sheet_values << sv
    end
  end

  def save_bt
    self.builder_task.save!
  end

  validates_existence_of :type

  named_scope :good, :conditions => ["cleaned_valid = ? AND original_valid = ?", true, true]
  named_scope :bad, :conditions => ["cleaned_valid = ? AND original_valid = ?", false, false]
  named_scope :originally_bad, :conditions => ["cleaned_valid = ? AND original_valid = ?", true, false]
  named_scope :clean_broke_it, :conditions => ["cleaned_valid = ? AND original_valid = ?", false, true]

  before_save :set_contract_id_and_covered
  before_save :builder_task

  def contact
    self.builder_task.contact
  end

  def action
    self.builder_task.action
  end

  def contract_id
    @contract_id ||= (system ? system.contract_id : nil)
  end

  def contact_id
    contact ? contact.id : nil
  end

  def builder_task_with_magic
    builder_task_without_magic || self.builder_task=(BuilderTask.new)
  end
  alias_method_chain :builder_task, :magic

  def contact_id=(val)
    self.builder_task.contact_id = val
  end

  def action_id
    action ? action.id : nil
  end

  def action_id=(val)
    self.builder_task.action_id = val
  end

  def after_initialize
    builder_task
  end

  def signed_off_by
    self.builder_task.signed_off_by
  end

  def signed_off_by=(val)
    self.builder_task.signed_off_by = val
  end

  def notes
    self.builder_task.notes
  end

  def notes=(val)
    self.builder_task.notes = val
  end

  def contract_id=(val)
    @contract_id = val
  end

  def covered
    @covered ||= (system ? system.covered : nil)
  end

  def covered=(val)
    @covered = val
  end

  def bug_correction
    self.system.bug_correction if self.system
  end

  def bug_correction=(val)
    self.system.bug_correction=(val) if self.system
  end

  def set_contract_id_and_covered
    if system
      if !(@contract_id.nil? || !(c = Contract.find(@contract_id)))
        system.contract = c
        system.save!
      end
      if !(@covered.nil?)
        system.covered = @covered
        system.save!
      end
    end
  end

  def lshw_output=(val)
    # if this record has already been saved, then don't let it change.
    if id.nil?
      self._lshw_output=(val)
    end
  end

  validates_presence_of :lshw_output

  def _lshw_output=(val)
#    write_attribute(:original_output, val)
    val = val.to_s
    file = Tempfile.new("fgss-xml")
    val.force_encoding('UTF-8')
    file.write(val)
    file.flush
    write_attribute(:original_valid, Kernel.system("xmlstarlet val #{file.path} >/dev/null 2>/dev/null"))
    write_attribute(:cleaned_output, val.gsub(/[^[:print:]\n\t]/, ''))
    file = Tempfile.new("fgss-xml")
    file.write(cleaned_output)
    file.flush
    write_attribute(:cleaned_valid, Kernel.system("xmlstarlet val #{file.path} >/dev/null 2>/dev/null"))
  end

  def lshw_output
    if cleaned_valid
      return cleaned_output
    elsif original_valid
      return original_output
    else
      return ""
    end
  end

  def xml_is_good
    cleaned_valid || original_valid
  end

  def most_recent_not_tech_support?
    return false if self.action.name == "tech_support"
    recent = self.system and self.system.spec_sheets.select{|x| x.action.name != "tech_support"}.sort_by(&:created_at).last
    return true unless recent
    return true if self.created_at.nil? or self.created_at >= recent.created_at
  end

  def set_extra_system_information(parsed)
    if most_recent_not_tech_support? and self.system
      self.system.last_build = self.created_at.nil? ? Date.today : self.created_at.to_date
      l = [:l1_cache_total, :l2_cache_total, :l3_cache_total, :north_bridge]
      if parsed.klass != SystemHelper::PlistSystemParser
        l = l + [:sixty_four_bit, :virtualization]
      end
      for i in l
        self.system.send(i.to_s + "=", parsed.send(i))
      end
      proc = parsed.processors.first
      if proc
        for i in [:processor_slot, :processor_product, :processor_speed]
          self.system.send(i.to_s + "=", proc.send(i.to_s.sub(/_product/, "").sub(/processor_/, "")))
        end
      end
      self.system.save! if self.system.id
    end
  end

  def parser
    SystemParser.parse(lshw_output)
  end

  def initialize(*args)
    super(*args)

    if !xml_is_good
      self.system_id = nil
      return
    end

    sp = self.parser
    found_system = System.find_by_id(sp.find_system_id)
    if found_system and !found_system.gone?
      self.system = found_system
    else
      self.system = System.new
      system.previous_id = found_system.id if found_system
      system.system_model  = sp.system_model
      system.system_serial_number  = sp.system_serial_number
      system.system_vendor  = sp.system_vendor
      system.mobo_model  = sp.mobo_model
      system.mobo_serial_number  = sp.mobo_serial_number
      system.mobo_vendor  = sp.mobo_vendor
      system.model  = sp.model
      system.serial_number  = sp.serial_number
      system.vendor  = sp.vendor
    end
    self.set_extra_system_information(sp)
  end
end
