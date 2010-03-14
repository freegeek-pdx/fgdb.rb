class HtmlTag
  attr_accessor :children, :attrs, :content
  attr_reader :tag
  def initialize(ptag, pattrs = {}, pchildren = [], pcontent = "")
    @children = pchildren
    @attrs = pattrs
    @content = pcontent
    @tag = ptag
  end

  def to_s
    str = ""
    str << "<#{tag}#{attrs.map{|name, val| " #{name}=\"#{val}\""}}>"
    str << children.map{|x| x.to_s}.join("\n")
    str << content.to_s
    str << "</#{tag}>"
    str
  end
end
