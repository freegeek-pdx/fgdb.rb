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

        def current_user
          Thread.current['user']
        end
      end
    end

    def create_with_user
      user = current_user
      if !user.nil?
        self[:created_by] = user.id if respond_to?(:created_by) && created_by.nil?
      end
      create_without_user
    end

    def update_with_user
      user = current_user
      self[:updated_by] = user.id if respond_to?(:updated_by) and !user.nil?
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
      if self.class.table_name != "logs"
        user = Thread.current['user']
        l = Log.new
        l.table_name = self.class.table_name
        l.action = action
        l.user_id = user.id if !user.nil?
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

  acts_as_logged
end
