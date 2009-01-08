class PrintmeAPI < SoapsBase
  include PrintmeHelper

  def add_methods
    # Connection Testing
    add_method("ping")
    # Version Checking
    add_method("version_compat", "client_version")
    add_method("version")
    add_method("bad_client_error")
    add_method("bad_server_error")
    # Lists
    add_method("actions")
    add_method("types")
    add_method("contracts")
    add_method("default_action_description")
    add_method("default_type_description")
    add_method("default_contract_label")
    # Printme
    add_method("empty_struct")
    add_method("submit", "printme_struct")
    # Notes
    add_method("empty_notes_struct")
    add_method("submit_notes", "notes_struct")
    add_method("get_system_for_note", "note_id")
    # Random Crap
    add_method("get_system_for_report", "report_id")
    add_method("contract_label_for_system", "system_id")
    add_method("type_description_for_system", "system_id")
    add_method("spec_sheet_url", "report_id")
    add_method("system_url", "system_id")
    add_method("get_system_id", "xml")
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
    10
  end
  def bad_client_error
    "You need to update your version of printme\nTo do that, go to System, then Administration, then Update Manager. When update manager comes up, click Check and then click Install Updates.\nAfter that finishes, run printme again."
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

  ###########
  # Printme #
  ###########

  PrintmeStruct = Struct.new(:contract_id, :action_id, :type_id, :contact_id, :old_id, :notes, :lshw_output, :os)  if !defined?(PrintmeStruct)

  def empty_struct
    PrintmeStruct.new
  end

  def submit(printme_struct)
    report = SpecSheet.new(:contract_id => printme_struct.contract_id, :action_id => printme_struct.action_id, :type_id => printme_struct.type_id, :contact_id => printme_struct.contact_id, :old_id => printme_struct.old_id, :notes => printme_struct.notes, :lshw_output => printme_struct.lshw_output, :os => printme_struct.os)
    begin
      report.save!
      if report.xml_is_good
        return report.id
      else
        return error("Invalid XML! Report id is #{report.id}. Please report this bug.")
      end
    rescue
      return error("Could not save the database record: #{$!.to_s}")
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
    rescue
      return error("Failed to save: #{$!.to_s}")
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
    System.find_by_id(system_id).spec_sheets.sort_by{|x| x.created_at}.last.type.description
  end

  def spec_sheet_url(report_id)
    "/spec_sheets/show/#{report_id}"
  end

  def system_url(system_id)
    "/spec_sheets/system/#{system_id}"
  end

  def get_system_id(xml)
    parse_stuff(xml)
    return find_system_id
  end

  #####
  #####
  public
end
