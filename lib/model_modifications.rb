require File.join(File.dirname(__FILE__), "rails_fix.rb")

class Bignum
  def valid_postgres_int?()
    return !(self > 2147483647 || self < -2147483648)
  end
end

class Fixnum
  def valid_postgres_int?()
    return true
  end
end

class Float
  def valid_postgres_int?()
    return !(self.to_i > 2147483647 || self.to_i < -2147483648)
  end
end

class ProcessorDaemon
  def self.add_to(type, tid, source = "fgdb")
    return false if Default['civicrm_server'].nil?
    tid = tid.to_i.to_s
    arr = [File.join(RAILS_ROOT, "script", "processor-daemon.sh"), "add", source, type, tid]
#    puts arr.inspect
    return system(*arr)
  end
end

module ActiveRecord
  module UserMonitor
    def self.included(base)
      base.class_eval do
        alias_method_chain :create, :user
        alias_method_chain :update, :user
        class << self
        def human_attribute_name_with_cashier_code(f)
          if f == 'cashier_code'
            return 'PIN'
          else
            return human_attribute_name_without_cashier_code(f)
          end
        end
          alias_method_chain :human_attribute_name, :cashier_code
        end

        belongs_to :creator, :foreign_key => "created_by", :class_name => "User"
        belongs_to :updator, :foreign_key => "created_by", :class_name => "User"
        validates_existence_of :creator, {:allow_nil => true}
        validates_existence_of :updator, {:allow_nil => true}
        validate :check_cashier
        def check_cashier
          if self.class.cashierable
            if self.class != Contact || current_user.nil? || current_user.contact_id.nil? || current_user.contact_id != self.id
              self.errors.add('cashier_code', 'is not valid') if !current_cashier
            end
          end
        end

        def current_user
          Thread.current['user']
        end

        def current_cashier
          Thread.current['cashier']
        end
      end
    end

    def create_with_user
      if self.class.record_timestamps
        user = current_user
        if !user.nil?
          self[:created_by] = user.id if respond_to?(:created_by) && created_by.nil?
        end
        cashier = current_cashier
        if respond_to?(:cashier_created_by) && cashier_created_by.nil?
          if !cashier.nil? #and self.class.cashierable
            self[:cashier_created_by] = cashier.id
          else
            self[:cashier_created_by] = self[:created_by]
          end
        end
      end
      create_without_user
    end

    def will_not_updated_timestamps!
      class << self
        def record_timestamps
          false
        end
      end
    end

    def update_with_user
      if self.class.record_timestamps
        user = current_user
        self[:updated_by] = user.id if respond_to?(:updated_by) and !user.nil?
        cashier = current_cashier
        if respond_to?(:cashier_updated_by)
          if !cashier.nil? and self.class.cashierable # TODO?
            self[:cashier_updated_by] = cashier.id
          else
            self[:cashier_updated_by] = self[:updated_by]
          end
        end
      end
      update_without_user
    end

    def created_by
      begin
        current_user.class.find(self[:created_by]) if current_user
      rescue ActiveRecord::RecordNotFound
        nil
      end
    end

    def updated_by
      begin
        current_user.class.find(self[:updated_by]) if current_user
      rescue ActiveRecord::RecordNotFound
        nil
      end
    end

    def cashier_created_by
      begin
        current_user.class.find(self[:cashier_created_by]) if current_user
      rescue ActiveRecord::RecordNotFound
        nil
      end
    end

    def cashier_updated_by
      begin
        current_user.class.find(self[:cashier_updated_by]) if current_user
      rescue ActiveRecord::RecordNotFound
        nil
      end
    end
  end

  module MyLogger
    def self.included(base)
      base.class_eval do
        alias_method_chain :update, :log
        alias_method_chain :create, :log
        alias_method_chain :destroy, :log
      end
    end

    def logaction(action)
      return if ! self.class.record_timestamps
      if self.class.table_name != "logs" && !self.id.nil? # AND (!["spec_sheets", "builder_tasks"].include?(self.class.table_name)) && 
        user = Thread.current['user']
#        raise "THIS IS YOUR INFO ... U: #{user.inspect} ... C: #{self.class.inspect} ... S: #{self.inspect}"
        cashier = Thread.current['cashier']
        l = Log.new
        l.table_name = self.class.table_name
        l.action = action
        l.user_id = user.id if !user.nil?
        l.cashier_id = cashier.id if self.class.cashierable && !cashier.nil?
        l.cashier_id = l.user_id if l.cashier_id.nil? && !l.user_id.nil?
        l.thing_id = self.id
        l.date = Time.now
        l.save!
      end
    end

    def create_with_log
      create_without_log
      logaction("create")
    end

    def destroy_with_log
      logaction("destroy")
      destroy_without_log
    end

    def update_with_log
      update_without_log
      logaction("update")
    end
  end
end

class Object
  def two_places
    v = sprintf "%.2f", self
#    if v[-1] == "0"[0]
#      v = v.chop
#    end
    v
  end

  def tp
    two_places
  end
end

class Struct
  def to_hash
    h = {}
    self.members.each{|x| x = x.to_sym; h[x] = self.send(x)}
    return h
  end
end

class String
  def to_cents
    tmp = self.sub(/^\$/, "")
    temp = tmp.split('.')
    temp[1]=((temp[1]||"0")+"0")[0..1]
    temp[0].to_i*100 + temp[1].to_i
  end
end

class Fixnum
  def to_dollars
    "%0d.%02d" % self.divmod(100)
  end
end

class OpenStruct
  def self.human_name
    "Data"
  end
  def self.human_attribute_name(attr)
    attr.humanize
  end
end

class ActiveRecord::Base
  def self.visible_columns
    self.all_columns.select{|x| ! self.hidden_columns.include?(x) }
  end

  def self.custom_option_selects
    []
  end

  def self.custom_options_for(opt)
    return {}[opt]
  end

  def self.type_override_for(opt)
    return {}[opt]
  end

  def self.editable_columns
    self.visible_columns.select{|x| ! self.readonly_columns.include?(x) }
  end

  def self.all_columns
    columns.map{|x| x.name.to_sym}
  end

  def self.per_page
    20
  end

        def self.hidden_columns
          [:lock_version]
        end

        def self.readonly_columns
          [:id, :created_at, :updated_at, :cashier_created_by, :cashier_updated_by, :created_by, :updated_by]
        end

        def self.associations
          retassociations = {}
          self.reflect_on_all_associations(:belongs_to).each do |x|
            column = x.options[:foreign_key] || x.name.to_s + "_id"
            klass = x.options[:class_name] || x.name.to_s.classify
            retassociations[column.to_sym] = klass.constantize
          end
          retassociations
        end

  def self.distinct(column, conds = [])
    self.find(:all, :conditions => conds, :select => "distinct #{column}").map{|x| x.send(column)}
  end

  def self.acts_as_userstamp
    include ActiveRecord::UserMonitor
  end

  def self.acts_as_logged
    include ActiveRecord::MyLogger
  end

  def self.define_amount_methods_on(method_name)
    code = "def #{method_name}
        (read_attribute(:#{method_name}_cents)||0).to_dollars
      end

      def #{method_name}=(value)
        if value.kind_of? String
          write_attribute(:#{method_name}_cents, value.to_cents)
        else
          raise TypeError.new(\"Integer math only. Use strings.\")
        end
      end"
    self.module_eval(code)
  end

  def self.define_amount_methods_on_fake_attr(method_name)
    code = "def #{method_name}
        ((#{method_name}_cents)||0).to_dollars
      end

      def #{method_name}=(value)
        if value.kind_of? String
          self.send(:#{method_name}_cents=, value.to_cents)
        else
          raise TypeError.new(\"Integer math only. Use strings.\")
        end
      end"
    self.module_eval(code)
  end

  def self.find_all_except(*recs)
    return find_all - recs
  end

  def self.cashierable_possible
    cols = self.columns.map{|x| x.name}
    cols.include?("cashier_updated_by") || columns.include?("cashier_created_by")
  end

  def self.allow_shared
    false
  end

  def self.cashierable
    return false if !self.cashierable_possible
    return true if self.new.current_user && self.new.current_user.shared && !self.allow_shared
    return Default[self.class_name.tableize + "_require_cashier_code"] ? true : false
  end

  def self.prepare_sql(*arr)
    a = arr
    if a.length == 1 and a.first.class == Array
      a = a.first
    end
    ret = sanitize_sql_for_conditions(a)
    return ret
  end

  def self.execute(*arr)
    connection.execute(prepare_sql(*arr))
  end

  def self.sql(*arr)
    prepare_sql(*arr)
  end

  def add_to_processor_daemon
    ProcessorDaemon.add_to(self.class.table_name, self.id)
  end

  def self.new_or_edit(hash)
    obj = nil
    if hash[:id] and hash[:id].to_i != 0
      obj = self.find(hash[:id].to_i)
      hash.delete(:id)
      obj.attributes_with_editable = hash
    else
      obj = self.new
      hash.delete(:id)
      obj.attributes = hash
    end
    return obj
  end

  def editable?
    editable = true
    if self.respond_to?(:editable)
      if ! self.editable
        editable = false
      end
    end
    return editable
  end

  def to_hash(*list)
    list = [list].flatten
    h = {}
    list.each do |k|
      h[k] = self.send(k)
    end
    h
  end

  def attributes_with_editable=(hash)
    should_check = !editable?
    before = attributes.clone
    retval = (self.attributes=(hash))
    after = attributes
    if should_check
      if before != after
        raise
      end
    end
    return retval
  end

  acts_as_logged


  protected

  def self.range_math(*ranges)
    frange = nil
    ranges.each{|a|
      pstart, pend = a
      pstart = (pstart.hour * 60) + pstart.min
      pend = (pend.hour * 60) + pend.min
      if frange.nil?
        frange = [[pstart, pend]]
      else
        frange.each{|a2|
          fstart, fend = a2
          if fstart < pstart and pstart < fend
            if pend >= fend
              fend = pstart
            else
              new = [pend, fend]
              frange.push(new)
              fend = pstart
            end
          elsif fstart >= pstart and fend <= pend
            fstart = fend = nil
          elsif pstart <= fstart and pend > fstart
            if pend > fend
              fstart = fend = nil # shouldn't get here
            else
              fstart = pend
            end
          end
          a2[0] = fstart
          a2[1] = fend
        }
        frange = frange.select{|x| !(x.first.nil? or x.first == x.last or x.last < x.first)}.sort_by{|x| x.first}
      end
    }
    return frange.map{|y| y.map{|x|
        hours = (x / 60).floor
        mins = x % 60
        Time.parse("#{hours}:#{mins}")
      }}
  end
end

class Array
  def each_with_siblings
    self.each_with_index{|b, i|
      a = self[i - 1] if i > 0 # -1 does not mean what we want it to
      c = self[i + 1]
      yield(a, b, c)
    }
  end

    def map_with_index
      result = []
      self.each_with_index do |elt, idx|
        result << yield(elt, idx)
      end
      result
    end
end

# lets call this a hack
# DB.execute("SELECT * FROM defaults;")
class DB < ActiveRecord::Base
  def self.exec(*args)
    DB.execute(*args)
  end
  def self.run(*args)
    DB.execute(*args)
  end
  def self.conditions_date_field
    return 'created_at'
  end
end

