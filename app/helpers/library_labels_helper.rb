module LibraryLabelsHelper
  PATH_TO_LABELS_STUFF=File.join(RAILS_ROOT, "vendor", "library_labels")
  LABEL=Default["label_type"] # 5662

  def run_thing(thing)
    ret = `#{thing} 2>&1`.chomp
    if $?.exitstatus != 0
      raise ret
    end
    return ret
  end

  def run_labels_script(scriptname, *args)
    run_thing([File.join(PATH_TO_LABELS_STUFF, scriptname + ".pl"), *args].join(" "))
  end

  # returns (cols, rows)
  def get_dimensions
    run_labels_script("get_info", LABEL).split(",")
  end

  # give it an array of copies
  def gen_pdf(array, pages, skips)
    tempfile = `mktemp -p #{File.join(RAILS_ROOT, "tmp", "tmp")}`.chomp
    basename = File.basename(tempfile).sub(".", "$")
    d = Tempfile.new("blah")
    d.write array.map{|x| Copy.find_by_id(x)}.map{|b| {:isbn => b.isbn, :author => b.author, :callno => b.call_number, :title => b.title, :barcode => b.barcode}}.to_xml
    d.flush
    run_labels_script("gen_pdf", tempfile, d.path, pages, LABEL, skips.join(","))
    system("cp #{d.path} foo")
    d.close
#    d.unlink
    return basename
  end
end
