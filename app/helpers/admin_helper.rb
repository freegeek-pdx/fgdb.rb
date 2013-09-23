module AdminHelper
  def admin_link_to(n, p, *o)
    link_to(n, p.class != Hash ? p : p.merge(:model => params[:model]), *o)
  end

  def get_column(name)
    @model.columns.select{|y| y.name == name.to_s}.first
  end

  def get_column_type(n)
    override = @model.type_override_for(n.to_sym)
    if override
      return override
    end
    get_column(n).type.to_s
  end

  def admin_form_for(n, p, *o)
    if p.class == Hash && p[:url]
      p[:url] = p[:url].merge(:model => params[:model])
    end
    form_for(n, p, *o) do |f|
      yield(f)
    end
  end
end
