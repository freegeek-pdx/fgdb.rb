require 'xsd/datatypes'
require 'soap/mapping'
require 'soap/rpc/element'
require 'soap/rpc/soaplet'

class SoapHandler
  def handle(req, res)
    @@mysoaplet.do_POST(req, res)
    res
  end

  def setup
    router = SOAP::RPC::Router.new("Soaps")
    Dir.glob(RAILS_ROOT + "/app/apis/*.rb").each{|x|
#      puts "Loading api from " + x
      if RAILS_ENV == "production"
        require x
      else
        eval(File.read(x))
      end
      eval("#{File.basename(x).capitalize.sub(/.rb$/, "")}API.new(router)")
    }
    SOAP::RPC::SOAPlet.new(router)
  end

  def initialize
    # remember all of the stuff between requests if we are in production mode
    if RAILS_ENV == "production"
      @@mysoaplet ||= setup
    else
      @@mysoaplet = setup
    end
  end
end

class SOAP::RPC::Router
  def my_add_method(obj, name, namespace, *param)
    qname = XSD::QName.new(namespace, name)
    soapaction = nil
    param_def = SOAP::RPC::SOAPMethod.derive_rpc_param_def(obj, name, *param)
    self.add_rpc_operation(obj, qname, soapaction, name, param_def)
  end
end

class SoapsBase
  def initialize(router)
    @router = router
    add_methods
  end
  def add_method(name, *param)
    namespace = "urn:" + self.class.to_s.underscore.sub("soap_handler/", "").sub(/_api$/, "")
#    puts "Adding soap method {#{namespace}}#{name}(#{param.join(", ")})"
    @router.send(:my_add_method, self, name, namespace, *param)
  end
  def error(message)
    SOAP::SOAPFault.new(SOAP::SOAPString.new("soaps"),
                        SOAP::SOAPString.new(message),
                        SOAP::SOAPString.new(self.class.name))
  end
end

class ActionController::CgiResponse
  def status=(thing)
    self.headers['Status'] = thing.to_s
  end
  def []=(a,b)
    self.headers[a] = b
  end
end

class ActionController::CgiRequest
  def meta_vars
    {'HTTP_SOAPACTION' => self.headers['Soapaction']}
  end
end

class ActionController::Routing::RouteSet
  def extract_request_environment_with_soap(req)
    hash = extract_request_environment_without_soap(req)
    hash[:soap] = !req.headers['Soapaction'].nil?
    hash
  end
  alias_method_chain :extract_request_environment, :soap
end

class ActionController::Routing::Route
  def recognition_conditions_with_soap
    res = recognition_conditions_without_soap
    res << "conditions[:soap] == env[:soap]" if conditions[:soap]
    res
  end
  alias_method_chain :recognition_conditions, :soap
end

class SoapController < ActionController::Base
  def index
    SoapHandler.new.handle(request, response)
    @performed_render = true
  end
end
