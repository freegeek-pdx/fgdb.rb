require_dependency RAILS_ROOT + "/app/helpers/system_helper.rb"

class PrintmeAPI < SOAP::SoapsBase
  include SystemHelper

  def add_methods
    for i in soap_methods
      add_method(*i)
    end
  end

  def soap_methods
    [
    # soap_methods access
    ["soap_methods"],
    # Connection Testing
    ["ping"],
    # Version Checking
    ["version_compat", "client_version"],
    ["version"],
    ["bad_client_error"],
    ["bad_mac_client_error"],
    ["bad_server_error"],
    # Lists
    ["actions"],
    ["types"],
    ["contracts"],
    ["coveredness_enabled"],
    ["default_action_description"],
    ["default_type_description"],
    ["default_contract_label"],
    # Printme
    ["empty_struct"],
    ["submit", "printme_struct"],
    # Notes
    ["empty_notes_struct"],
    ["submit_notes", "notes_struct"],
    ["get_system_for_note", "note_id"],
    # Random Crap
    ["get_extra_questions"],
    ["get_system_for_report", "report_id"],
    ["contract_label_for_system", "system_id"],
    ["type_description_for_system", "system_id"],
    ["covered_for_system", "system_id"],
    ["spec_sheet_url", "report_id"],
    ["system_url", "system_id"],
    ["is_system_gone", "system_id"],
    ["question_defaults", "system_id"],
    ["get_system_id", "xml"],
    ["is_valid_contact", "contact_id"]
    ]
  end

  def is_valid_contact(contact_id)
    !! Contact.find_by_id(contact_id.to_i)
  end

  SpecSheetQuestionStruct = Struct.new(:id_name, :name, :question, :conditions) if !defined?(SpecSheetQuestionStruct)
  SpecSheetConditionStruct = Struct.new(:field_name, :operator, :expected_value) if !defined?(SpecSheetConditionStruct)

  def get_extra_questions
    SpecSheetQuestion.find(:all).sort_by(&:position).map{|x|
      a = x.spec_sheet_question_conditions.map{|y|
        SpecSheetConditionStruct.new(y.name, y.operator, y.expected_value)
      }
      SpecSheetQuestionStruct.new("id_" + x.id.to_s, x.real_name, x.question, a)
    }
  end

  ######################
  # Connection Testing #
  ######################

  def ping
#    return error("BOO")
    "pong"
  end

  ####################
  # Version Checking #
  ####################

  public
  def version_compat(client_version)
    server_hash[version].class != Array || server_hash[version].include?(client_version)
  end
  def version
    17
  end
  def bad_client_error
    "You need to update your version of printme\nTo do that, go to System, then Administration, then Update Manager. When update manager comes up, click Check and then click Install Updates.\nAfter that finishes, run printme again."
  end
  def bad_mac_client_error
    "You need to update your version of printme\nTo do that, see the instructions on the wiki at http://wiki.freegeek.org/index.php/Printme#Mac_Printme and then run printme again.\n"
  end
  def bad_server_error
    "The server is incompatible. exiting."
  end

  private
  def server_hash
    server_versions = Hash.new([])
    server_versions[1] = [1]      # I don't remember...but I know that it wouldn't have gotten to this point :)
    server_versions[2] = [2,3,4]  # really 2-4 are all compatible with all versions
    server_versions[3] = [3,4]    # force client upgrade. so of course old ones aren't compatible. (field renames)
    server_versions[4] = [4]      # yet another force client upgrade. (server version checking)
    server_versions[5] = [5]      # force upgrade. printme no longer fixes the xml.
    server_versions[6] = [6]      # forced. add contracts support.
    server_versions[7] = [7]      # forced. fix contracts support. (bad builder problem)
    server_versions[8] = [8]      # forced. fix contracts support. (my bugs)
    server_versions[9] = [9]      # rewrite with soap...FORCED!!! :)
    server_versions[10] = [9,10]  # all good
    server_versions[11] = [11]    # string change on both ends, that needs to go together (reworded contracts question)
    server_versions[12] = [12]    # new info collected, forced upgrade.
    server_versions[13] = [12,13]    # works fine.
    server_versions[14] = [14] # previous systems
    server_versions[15] = [15] # conditional Q's
    server_versions[16] = [16] # OR'ed conditional Q's
    server_versions[17] = [17]
    server_versions
  end

  #########
  # Lists #
  #########

  ActionStruct = Struct.new( :name, :description, :thing_id ) if !defined?(ActionStruct)
  TypeStruct = Struct.new( :name, :description, :thing_id ) if !defined?(TypeStruct)
  ContractStruct = Struct.new( :name, :label, :thing_id ) if !defined?(ContractStruct)

  public
  def actions
    Action.usable.map{|x| ActionStruct.new(x.name, x.description, x.id)}
  end
  def types
    Type.usable.map{|x| TypeStruct.new(x.name, x.description, x.id)}
  end
  def contracts
    Contract.usable.map{|x| ContractStruct.new(x.name, x.label, x.id)}
  end
  def default_action_description
    Action.find_by_name('checker').description
  end
  def default_type_description
    Type.find_by_name('regular').description
  end
  def default_contract_label
    Contract.find_by_name('default').label
  end
  def coveredness_enabled
    Default["coveredness_enabled"] == "1"
  end

  ###########
  # Printme #
  ###########

  PrintmeStruct = Struct.new(:contract_id, :action_id, :type_id, :contact_id, :old_id, :notes, :lshw_output, :os, :covered, :questions)  if !defined?(PrintmeStruct)

  def empty_struct
    PrintmeStruct.new
  end

  def submit(printme_struct)
    input = nil
    if printme_struct.class == Hash
      input = printme_struct
    else
      struct = PrintmeStruct.new
      struct.members.each{|x| struct.send(x.to_s + "=", printme_struct.send(x))}
      input = struct.to_hash
    end
    report = SpecSheet.new(input)
    begin
      report.save!
      if report.xml_is_good
        return report.id
      else
        begin
          raise "Invalid XML! Report id is #{report.id}. Please report this bug."
        rescue => e
          return error(e, "Could not parse the XML: ") # TODO: should move into a wrapper
        end
      end
    rescue => e
      return error(e, "Could not save the database record: ")
    end
  end

  #########
  # Notes #
  #########

  NoteStruct = Struct.new(:contact_id, :body, :lshw_output) if !defined?(NoteStruct)

  def empty_notes_struct
    NoteStruct.new
  end

  def submit_notes(notes_struct)
    notes = Note.new(:contact_id => notes_struct.contact_id, :body => notes_struct.body, :lshw_output => notes_struct.lshw_output)
    begin
      notes.save!
    rescue => e
      return error(e, "Failed to save: ")
    end
    return notes.id
  end

  def get_system_for_note(note_id)
    return Note.find_by_id(note_id).system.id
  end

  ###############
  # Random Crap #
  ###############

  def get_system_for_report(report_id)
    SpecSheet.find_by_id(report_id).system.id
  end

  def contract_label_for_system(system_id)
    System.find_by_id(system_id).contract.label
  end

  def type_description_for_system(system_id)
    sys = System.find_by_id(system_id)
    spec = sys ? sys.spec_sheets.sort_by{|x| x.created_at}.last : nil
    if spec
      return spec.type.description
    else
      return default_type_description
    end
  end

  def question_defaults(system_id)
    sys = System.find_by_id(system_id)
    spec = sys ? sys.spec_sheets.sort_by{|x| x.created_at}.last : nil
    values = spec ? spec.spec_sheet_values : []
    hash = {}
    values.each do |x|
      hash[x.spec_sheet_question.real_name] = x.value
    end
    hash.to_a
  end

  def covered_for_system(system_id)
    System.find_by_id(system_id).covered
  end

  def spec_sheet_url(report_id)
    "/spec_sheets/show/#{report_id}"
  end

  def system_url(system_id)
    "/spec_sheets/system/#{system_id}"
  end

  def get_system_id(xml)
    sp = SystemHelper::SystemParser.parse(xml)
    return sp.find_system_id
  end

  def is_system_gone(system_id)
    System.find(system_id).gone?
  end

  #####
  #####
  public
end

