Dir.glob(RAILS_ROOT + "/app/apis/*.rb").each{|x|
  require_dependency x
}

# RES: {:status => "success", :result => []}
# ERR: {:status => "error", :message => "BLAH"}
class ApiController < ApplicationController
  def handle
    n = params[:namespace]
    m = params[:method]
    r = JSON.parse(params[:request] || "[]")
    handler = SOAP::SoapsBase.all[n]
    if handler.nil?
      ret = error("No API handler found for: #{n}:#{m}(#{r.length})")
    else
      method = handler.methods[m]
      if method.nil? || method.length != r.length
        ret = error("No API handler found for: #{n}:#{m}(#{r.length})")
      else
        res = handler.send(m.to_sym, *r)
        if res.class == SOAP::SOAPFault
          ret = error(res.faultstring.data)
        else
          ret = success(res)
        end
      end
    end
    render :text => ret
  end

  private
  def error(message)
    return {:status => "error", :message => message}.to_json
  end

  def success(result)
    return {:status => "success", :result => result}.to_json
  end
end
