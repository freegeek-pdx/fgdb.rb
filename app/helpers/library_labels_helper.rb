module LibraryLabelsHelper
  PATH_TO_LABELS_STUFF="/home/ryan52/library_labels"
#  PATH_TO_LABELS_STUFF=File.join(RAILS_ROOT, "vendor", "library_labels")
  LABEL="5662"

  def run_thing(thing)
    print thing
    ret = `#{thing} 2>&1`.chomp
    if $?.exitstatus != 0
      raise ret
    end
    return ret
  end

  def run_labels_script(scriptname, *args)
    run_thing(["perl", "-I#{PATH_TO_LABELS_STUFF}", File.join(PATH_TO_LABELS_STUFF, scriptname), *args].join(" "))
  end

  # returns (cols, rows)
  def get_dimensions
    run_labels_script("get_info.pl", LABEL).split(",")
  end
end
