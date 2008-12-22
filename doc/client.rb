#!/usr/bin/ruby

require 'soap/rpc/driver'

driver = SOAP::RPC::Driver.new("http://localhost:3000/", "urn:soaps")
driver.add_method("hi")
driver.add_method("fivetimes", "num")
puts driver.hi
puts driver.fivetimes(6).class
puts driver.fivetimes(6)
