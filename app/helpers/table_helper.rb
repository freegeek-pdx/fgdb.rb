module TableHelper
  protected
  def make_table(a, html_opts = {}, full_width = true, noptoprow = false)
    trs = a.map_with_index{|x, i|
      subtype = "first"
      subtype = "all" if i == 0 unless noptoprow
      table_make_tr(subtype, x)
    }
    width = full_width ? {:width => "98%"} : {}
    HtmlTag.new("table", width.merge({:border => 1, :style => "border-collapse: collapse;"}).merge(html_opts), trs)
  end

  def table_make_tr(type, a)
    opts = {}
    if a.first.class == Hash
      opts = a.shift
    end
    childs = a.map_with_index{|x, i|
      subtype = "td"
      subtype = "th" if (type == "first" && i == 0) or type == "all"
      table_make_td(subtype, x)
    }
    HtmlTag.new("tr", opts, childs)
  end

  def table_make_td(type, value)
    if value.class == Array and value[0] == :a
      href = url_for(value[1])
      return HtmlTag.new(type, {}, [HtmlTag.new(value[0].to_s, {:href => href}, [], value[2].to_s)])
    end
    HtmlTag.new(type, {}, [], value.to_s)
  end
end
