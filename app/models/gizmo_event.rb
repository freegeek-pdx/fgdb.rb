class GizmoEvent < ActiveRecord::Base
  belongs_to :donation
  belongs_to :sale
  belongs_to :disbursement
  belongs_to :recycling
  belongs_to :gizmo_type
  belongs_to :gizmo_category
  belongs_to  :gizmo_context
  has_many :gizmo_events_gizmo_typeattrs, :dependent => :destroy

  validates_presence_of :gizmo_count
  validates_presence_of :gizmo_type_id
  validates_presence_of :gizmo_context_id

  define_amount_methods_on("adjusted_fee")

  class << self
    def totals(conditions)
      connection.execute(
        "SELECT gizmo_events.gizmo_type_id,
                gizmo_events.gizmo_context_id,
                d.disbursement_type_id,
                sum(gizmo_events.gizmo_count)
         FROM gizmo_events
              LEFT OUTER JOIN disbursements AS d ON d.id = gizmo_events.disbursement_id
         WHERE #{sanitize_sql_for_conditions(conditions)}
         GROUP BY 2,1,3"
      )
    end

    def category_totals(conditions)
      connection.execute(
        "SELECT gizmo_types.gizmo_category_id,
                gizmo_events.gizmo_context_id,
                sum(gizmo_events.gizmo_count)
         FROM gizmo_events
              LEFT JOIN gizmo_types ON gizmo_types.id=gizmo_events.gizmo_type_id
         WHERE #{sanitize_sql_for_conditions(conditions)}
         GROUP BY 1,2"
                         )
    end

    def income_totals(conditions)
      conditions = conditions.dup()
      conditions[0] += " AND gegt.gizmo_typeattr_id=14"
      connection.execute(
        "SELECT gt.id, 
                sum(gizmo_events.gizmo_count 
                    * gegt.attr_val_monetary_cents)
         FROM gizmo_events 
              LEFT JOIN gizmo_events_gizmo_typeattrs gegt
                   ON gizmo_events.id=gegt.gizmo_event_id
              LEFT JOIN gizmo_types gt 
                   ON gizmo_events.gizmo_type_id=gt.id 
         WHERE #{sanitize_sql_for_conditions(conditions)}
         GROUP by 1")
    end
  end

  def display_name
    "%i %s%s" % [gizmo_count, gizmo_type.description, gizmo_count > 1 ? 's' : '']
  end

  def gizmo_attrs
    if gizmo_type and gizmo_context
      gizmo_type.relevant_attrs(gizmo_context)
    else
      []
    end
  end

  def valid_gizmo_count?
     gizmo_count.is_a?(Fixnum) and gizmo_count > 0
  end

  def attry_description(options = {})
    attrs = {}
    gizmo_events_gizmo_typeattrs.each {|bridge|
      next unless bridge.value
      next if( options[:ignore].respond_to?('include?') &&
               (options[:ignore].include?(bridge.gizmo_typeattr.gizmo_attr.name)) )
      attrs[bridge.gizmo_typeattr.gizmo_attr.name] = bridge.value
    }

    attrs.delete_if {|attr,value|
      ! value or (value.respond_to?(:empty?) and value.empty?)
    }
    if attrs.empty?
      gizmo_type.description
    else
      gizmo_type.description + " (" +
        attrs.map {|name,value|
        "%s: %s" % [name, value]
      }.join(', ') + ")"
    end
  end

  def possible_attrs
    if gizmo_type
      gizmo_type.possible_attrs
    else
      GizmoAttr.find(:all)
    end
  end

  def gizmo_typeattrs
    if gizmo_type and gizmo_context
      gizmo_type.relevant_typeattrs(gizmo_context)
    else
      []
    end
  end

  def percent_discount(schedule)
    return 0 unless schedule && gizmo_type
    ( ( 1.0 - gizmo_type.multiplier_to_apply(schedule) ) * 100 ).ceil
  end

  def total_price_cents
    return 0 unless unit_price_cents and gizmo_count
    unit_price_cents * gizmo_count
  end

  def discounted_price(schedule)
    return total_price_cents unless schedule && gizmo_type
    (total_price_cents * (gizmo_type.multiplier_to_apply(schedule) * 100).to_i)/100
  end

  def mostly_empty?
    ((! gizmo_type_id) or (! gizmo_count))
  end

  def required_fee_cents
    if (adjusted_fee_cents||0) > 0
      gizmo_count.to_i * adjusted_fee_cents
    else
      gizmo_count.to_i * gizmo_type.required_fee_cents
    end
  end

  def suggested_fee_cents
    gizmo_count.to_i * gizmo_type.suggested_fee_cents
  end

  def to_s
    "id[#{id}]; type[#{gizmo_type_id}]; context[#{gizmo_context_id}]; count[#{gizmo_count}]"
  end

  def unit_price_cents
    unit_price.to_cents
  end

  def initialize_gizmo_attrs
    attrs = {}
    gizmo_events_gizmo_typeattrs.each {|attr|
      attrs[attr.gizmo_typeattr.gizmo_attr.name] = attr.value
    }
    attrs
  end

  def method_missing_with_gizmo_attrs(sym, *args, &block)
    attr_name = sym.to_s.sub(/=/, '')
    if possible_attrs.detect {|attr| attr.name == attr_name }
      @gizmo_attrs ||= initialize_gizmo_attrs
      if attr_name == sym.to_s
        return @gizmo_attrs[attr_name]
      else
        return @gizmo_attrs[attr_name] = args[0]
      end
    end
    method_missing_without_gizmo_attrs(sym, *args, &block)
  end
  alias :method_missing_without_gizmo_attrs :method_missing
  alias :method_missing :method_missing_with_gizmo_attrs

  before_save :setup_gizmo_attrs
  def setup_gizmo_attrs
    if @gizmo_attrs
      self.gizmo_events_gizmo_typeattrs = gizmo_typeattrs.map {|typeattr|
        attr_entry = GizmoEventsGizmoTypeattr.new
        attr_entry.gizmo_event = self
        attr_entry.gizmo_typeattr = typeattr
        attr_entry.value = @gizmo_attrs[typeattr.gizmo_attr.name]
        attr_entry
      }
    end
  end
end
