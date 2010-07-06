require 'xapian'
require 'posixlock'

class XapianBase
  def self.path
    base = File.join(RAILS_ROOT, "tmp", "xapian")
    if !File.exists?(base)
      FileUtils.mkdir(base)
    end
    return File.join(base, RAILS_ENV)
  end
end

class XapianReader < XapianBase
  def initialize
    db = Xapian::Database.new(XapianBase.path)
    stem = Xapian::Stem.new("english")
    @enquire = Xapian::Enquire.new(db)
    @qp = Xapian::QueryParser.new()
    @qp.stemmer = stem
    @qp.database = db
    @qp.stemming_strategy = Xapian::QueryParser::STEM_SOME
  end

  def search(*args)
    XapianResults.new(get_enquire_for_query(*args))
  end

  private
  def get_enquire_for_query(query)
    @enquire.query = @qp.parse_query(query, Xapian::QueryParser::FLAG_BOOLEAN | Xapian::QueryParser::FLAG_PHRASE | Xapian::QueryParser::FLAG_LOVEHATE | Xapian::QueryParser::FLAG_WILDCARD | Xapian::QueryParser::FLAG_SPELLING_CORRECTION)
    @enquire.sort_by_relevance!
    @enquire
  end
end

class XapianResults
  def initialize(enquire)
    @enquire = enquire
  end

  def paginate(opts)
    per_page = opts[:per_page] ? opts[:per_page].to_i : 10
    page = opts[:page] ? opts[:page].to_i : 1
    first = (per_page * (page - 1)) + 1
    mset = @enquire.mset(per_page * (page - 1), per_page)
    WillPaginate::Collection.create(page, per_page, mset.matches_estimated) do |pager|
      pager.replace convert_mset_to_objects(mset)
    end
  end

  def matches
    convert_mset_to_objects(@enquire.mset(0, 10000000))
  end

  def convert_mset_to_objects(mset)
    mset.matches.map{|m|
      convert_match_to_object(m)
    }
  end

  def convert_match_to_object(m)
    a = m.document.data.split(/-/)
    a[0].constantize.find(a[1].to_i)
  end
end

class XapianWriter < XapianBase
  def initialize
    file = File.join(XapianBase.path)
    if !File.exists?(file)
      XapianJob.destroy_all
      Book.rebuild_index
    end
    @db = Xapian::WritableDatabase.new(file, Xapian::DB_CREATE_OR_OPEN)
    @indexer = Xapian::TermGenerator.new()
    stem = Xapian::Stem.new("english")
    @indexer.stemmer = stem
    @indexer.database = @db
  end

  def process(thing_id, klass)
    opts = klass.acts_like_xapian_opts
    if (@res = klass.find_by_id(thing_id))
      update_entry(thing_id, klass, opts)
    else
      destroy_entry(thing_id, klass, opts)
    end
    puts "processed #{klass.to_s} ##{thing_id} with options #{opts.inspect}"
    $stdout.flush
    @db.flush
  end

  def update_entry(*args)
    @db.replace_document("Z" + get_xapian_string_for_thing(*args), get_doc_for_thing(*args))
  end

  def get_doc_for_thing(thing_id, klass, opts = {})
    string = get_xapian_string_for_thing(thing_id, klass, opts)
    doc = Xapian::Document.new
    @indexer.document = doc
    doc.data = string
    doc.add_term("Z" + string)
    @indexer.increase_termpos
    @indexer.index_text(@res.title.to_s, 1) # TODO: get from opts
    doc
  end

  def destroy_entry(*args)
    @db.delete_document("Z" + get_xapian_string_for_thing(*args))
  end

  def get_xapian_string_for_thing(thing_id, klass, opts = {})
    klass.to_s + "-" + thing_id.to_s
  end
end

module ActsAsXapian
  def self.included(base)
    base.extend(ActsAsXapian::ClassMethods)
  end

  module InstanceMethods
    def acts_like_xapian_opts
      self.class.acts_like_xapian_opts
    end

    def update_record_xapian
      id = 0
      if acts_like_xapian_opts[:parent]
        id = self.send(acts_like_xapian_opts[:parent].to_sym).id
      else
        id = self.id
      end
      XapianJob.new(:book_id => id).save!
    end
  end

  module ClassMethods
    def acts_like_parent_is_xapian(opts)
      raise "parent key is required for acts_like_parent_is_xapian" if !opts[:parent]
      @@opts = opts
      include ActsAsXapian::InstanceMethods
      instance_eval do
        after_update :update_record_xapian
        after_create :update_record_xapian
        before_destroy :update_record_xapian
        def acts_like_xapian_opts
          @@opts
        end
      end
    end

    def acts_like_xapian(opts)
      raise "parent key cannot be used with acts_like_xapian" if opts[:parent]
      @@opts = opts
      @@is_xapian = true
      include ActsAsXapian::InstanceMethods
      instance_eval do
        after_update :update_record_xapian
        after_create :update_record_xapian
        before_destroy :update_record_xapian
        def search(*p)
          XapianReader.new.search(*p)
        end
        def self.rebuild_index
          self.find(:all).each{|x| x.update_record_xapian}
        end
        def acts_like_xapian_opts
          @@opts
        end
      end
    end
  end
end

# TODO: go through all the scenarios and check for race conditions
class RunXapianDaemon
  def self.path
    XapianBase.path
  end

  def self.run
    return if !lock_parent_process
    out = `env I_AM_TEH_XAPIAN_DAEMON=true RAILS_ENV=#{RAILS_ENV} #{File.join(RAILS_ROOT, "script", "daemonize.pl")} #{File.join(RAILS_ROOT, "script", "runner")} 'XapianDaemon.new.run' 2>&1`
    if $?.exitstatus != 0
      raise out
    end
  end

  def self.lock_parent_process
    if RunXapianDaemon.parent_process_running?
      begin
        RunXapianDaemon.wait_for_daemon_process
        return false
      rescue "Xapian daemon process did not come to life"
        RunXapianDaemon._do_parent_lock_thing
      end
    else
      RunXapianDaemon._do_parent_lock_thing
    end
    return true
  end

  def self.go
    return if ENV['I_AM_TEH_XAPIAN_DAEMON']
    return if !XapianJob.table_exists?
    if !RunXapianDaemon.is_ready?
      RunXapianDaemon.run
      RunXapianDaemon.wait_for_daemon_process
    end
  end

  def self.wait_for_daemon_process
    60.times do
      return 0 if RunXapianDaemon.is_ready?
      sleep 0.5
    end
    raise "Xapian daemon process did not come to life"
  end

  ##################################
  # Boring flock stuff starts here #
  ##################################

  def self._do_parent_lock_thing
    do_lockf("parent", File::F_LOCKW)
  end

  def self.parent_process_running?
    do_lockf("parent", File::F_TESTW)
  end

  def self.lock_daemon_process
    do_lockf("daemon", File::F_TLOCKW)
  end

  def self.is_running?
    do_lockf("daemon", File::F_TESTW)
  end

  def self.lock_ready
    do_lockf("ready", File::F_TLOCKW)
  end

  def self.is_ready?
    do_lockf("ready", File::F_TESTW)
  end

  def self.do_lockf(filename, lock)
    file = File.join(RAILS_ROOT, "tmp", "pids", filename)
    FileUtils.touch(file)
    f = File.open(file, "w")
    ret = f.lockf(lock, 0)
    if ![File::F_TESTW, File::F_TESTR].include?(lock)
      @@pids ||= []
      @@pids << f
    else
      f.close
    end
    return ret
  end
end

class XapianDaemon
  def initialize
    RunXapianDaemon.lock_daemon_process
    @xw = XapianWriter.new
    @out = File.open(File.join(RAILS_ROOT, "log", "xapian.log"), "a")
    @err = File.open(File.join(RAILS_ROOT, "log", "xapian.error.log"), "a")
    $stderr.reopen(@err)
    $stdout.reopen(@out)
    RunXapianDaemon.lock_ready
    puts "I'm ready (pid: #{Process.pid})"
    $stdout.flush
  end

  def get_pending_jobs
    XapianJob.find(:all).map{|x| x.book_id}.uniq
  end

  def process_all_pending_jobs
    jobs = get_pending_jobs
    if jobs and jobs.length > 0
      jobs.each{|x|
        process_job(x)
      }
      while res = XapianJob.find_by_book_id(jobs)
        break if res == nil
        [res].flatten.each{|x| x.destroy || raise}
      end
    end
  end

  def process_job(job)
    @xw.process(job, Book)
  end

  def run
    i = 20
    while RunXapianDaemon.parent_process_running?
      if i == 20
        process_all_pending_jobs
        i = 0
      end
      sleep 0.5
      i += 1
    end
    puts "I'm done (pid: #{Process.pid})"
    $stdout.flush
  end
end

ActiveRecord::Base.send :include, ActsAsXapian
RunXapianDaemon.go
