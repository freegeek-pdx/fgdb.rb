module SOAP
class SoapsBase
  include ApplicationHelper

  attr_accessor :api, :methods, :error

  def self.all
    @@all
  end

  def initialize
    @methods = {}
    @api = self.class.to_s.underscore.sub("soap_handler/", "").sub(/_api$/, "")
    @@all ||= {}
    @@all[@api] = self
    add_methods
  end

  def add_method(name, *param)
    namespace = "urn:" + @api
    @methods[name] = param
#    puts "Adding soap method {#{namespace}}#{name}(#{param.join(", ")})"
    MyAPIPort.port.add_method(self, name, namespace, *param)
  end

  def error(e, msg = "")
#    ret = save_exception_data(e)
    # FIXME e handling .message
    message = "HERE: " + msg + e.message # + " (crash id #{ret["crash_id"]})"
    message += "\n\n" + e.backtrace.join("\n")
    SOAP::SOAPFault.new(SOAP::SOAPString.new("soaps"),
                        SOAP::SOAPString.new(message),
                        SOAP::SOAPString.new(self.class.name))
  end
end
end

Dir.glob(RAILS_ROOT + "/app/apis/*.rb").each{|x|
# puts "Loading API: #{x}"
 require_dependency x
}
SOAP::SoapsBase.subclasses.map{|x| x.constantize}.each{|x| x.new}
