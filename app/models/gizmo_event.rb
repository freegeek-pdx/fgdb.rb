class GizmoEvent < ActiveRecord::Base
  named_scope :not_discount, :conditions => ["gizmo_type_id != ?", GizmoType.find_by_name("fee_discount").id]

  belongs_to :donation
  belongs_to :sale
  belongs_to :disbursement
  belongs_to :recycling
  belongs_to :gizmo_type
  belongs_to :gizmo_category
  belongs_to  :gizmo_context
  belongs_to :system

  validates_presence_of :gizmo_count
  validates_presence_of :gizmo_type_id
  validates_presence_of :gizmo_context_id

  define_amount_methods_on("unit_price")

  def validate
    if gizmo_type && gizmo_type.gizmo_category && gizmo_type.gizmo_category.name == "system" && !system_id.nil? && gizmo_count != 1
      errors.add("gizmo_count", "should be 1 if you enter a system id")
    end
    if (!gizmo_type || !gizmo_type.gizmo_category || gizmo_type.gizmo_category.name != "system") && !system_id.nil?
      errors.add("system_id", "should only be set if the type is a system")
    end
    if !system_id.nil? && self.system.nil?
      errors.add("system_id", "does not refer to a valid system")
    end
  end

  class << self
    def totals(conditions)
      connection.execute(
                         "SELECT gizmo_events.gizmo_type_id,
                gizmo_events.gizmo_context_id,
                d.disbursement_type_id,
                sum(gizmo_events.gizmo_count) AS count
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
      connection.execute(
                         "SELECT gt.id AS gt,
                sum(gizmo_events.gizmo_count
                    * gizmo_events.unit_price_cents)
         FROM gizmo_events
              LEFT JOIN gizmo_types gt
                   ON gizmo_events.gizmo_type_id=gt.id
         WHERE #{sanitize_sql_for_conditions(conditions)}
         GROUP by 1")
    end
  end

  def display_name
    "%i %s%s" % [gizmo_count, gizmo_type.description, gizmo_count > 1 ? 's' : '']
  end

  def valid_gizmo_count?
    gizmo_count.is_a?(Fixnum) and gizmo_count > 0
  end

  def attry_description(options = {})
    junk = [:unit_price, :as_is, :size, :system_id] - (options[:ignore] || [])

    junk.reject!{|x| z = read_attribute(x); z.nil? || z.to_s.empty?}

    g_desc = gizmo_type.description
    m_desc = self.description
    desc = g_desc
    desc += " -- " + m_desc if !(m_desc.nil? || m_desc.empty?)

    if junk.empty?
      return desc
    else
      return desc + "(" + junk.map{|x| x.to_s.classify.gsub(/(.)([A-Z])/, "\\1 \\2") + ": " + read_attribute(x).to_s}.join(", ") + ")"
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

  def fee_cents
    unit_price_cents
  end

  def required_fee_cents
    if !covered && gizmo_type.required_fee_cents != 0 || gizmo_type.name == "fee_discount"
      gizmo_count.to_i * (unit_price_cents || gizmo_type.required_fee_cents)
    else
      0
    end
  end

  def suggested_fee_cents
    if (covered && gizmo_type.required_fee_cents != 0) || gizmo_type.suggested_fee_cents != 0
      gizmo_count.to_i * (unit_price_cents || gizmo_type.required_fee_cents || gizmo_type.suggested_fee_cents)
    else
      0
    end
  end

  def to_s
    "id[#{id}]; type[#{gizmo_type_id}]; context[#{gizmo_context_id}]; count[#{gizmo_count}]"
  end
end
