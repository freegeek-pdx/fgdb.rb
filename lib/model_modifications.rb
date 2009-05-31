module ActiveRecord
  module UserMonitor
    def self.included(base)
      base.class_eval do
        alias_method_chain :create, :user
        alias_method_chain :update, :user

        belongs_to :creator, :foreign_key => "created_by", :class_name => "User"
        belongs_to :updator, :foreign_key => "created_by", :class_name => "User"
        validates_existence_of :creator, {:allow_nil => true}
        validates_existence_of :updator, {:allow_nil => true}
        validate :check_cashier
        def check_cashier
          if self.class.cashierable
            self.errors.add('cashier_code', 'is not valid') if !current_cashier
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
      user = current_user
      if !user.nil?
        self[:created_by] = user.id if respond_to?(:created_by) && created_by.nil?
      end
      cashier = current_cashier
      if respond_to?(:cashier_created_by) && cashier_created_by.nil?
        if !cashier.nil? and self.class.cashierable
          self[:cashier_created_by] = cashier.id
        else
          self[:cashier_created_by] = self[:created_by]
        end
      end
      create_without_user
    end

    def update_with_user
      user = current_user
      self[:updated_by] = user.id if respond_to?(:updated_by) and !user.nil?
      cashier = current_cashier
      if respond_to?(:cashier_updated_by)
        if self.class.cashierable and !cashier.nil?
          self[:cashier_updated_by] = cashier.id
        else
          self[:cashier_updated_by] = self[:updated_by]
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
      if self.class.table_name != "logs" && !self.id.nil?
        user = Thread.current['user']
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

class String
  def to_cents
    temp = self.split('.')
    temp[1]=((temp[1]||"0")+"0")[0..1]
    temp[0].to_i*100 + temp[1].to_i
  end
end

class Fixnum
  def to_dollars
    "%0d.%02d" % self.divmod(100)
  end
end

class ActiveRecord::Base
  def my_link_to(name, opts)
    "@LINK@" + name.to_s + "@PARAMS@" + opts.inspect + "@ENDLINK@"
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

  def self.find_all_except(*recs)
    return find_all - recs
  end

  def self.cashierable
    columns = self.columns.map{|x| x.name}
    avail = columns.include?("cashier_updated_by") || columns.include?("cashier_created_by")
    return false if !avail
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
    execute(*arr)
  end

  acts_as_logged
end

# lets call this a hack
# DB.execute("SELECT * FROM defaults;")
class DB < ActiveRecord::Base
end
