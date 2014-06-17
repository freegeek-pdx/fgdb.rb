# #!/usr/bin/env ruby
# 
# #ENV['RAILS_ENV']||="production"
# 
# require File.dirname(__FILE__) + '/../config/boot'
# require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
# 
# d = Date.today
# while d.wday != 1
#   d -= 1
# end # find the monday of this week
# d -= 7 # jump to the previous week
# date_conds = [[d -7, d-1], [d, d+6]] # get that previous week and the week before
# data = ""
# data += "== Overtime Report ==\n"
# date_conds.each {|start, fin|
#   holidays = (start..fin).to_a.select{|x| Holiday.is_holiday?(x)}
#   data +=  "\n"
#   data +=  "Overtime for week of #{start.strftime("%D")}-#{fin.strftime("%D")}:\n"
#   DB.execute(["SELECT workers.id AS id, workers.name AS worker, workers.ceiling_hours AS ceiling, SUM( duration ) AS actual from worked_shifts JOIN workers ON worked_shifts.worker_id = workers.id WHERE NOT workers.salaried AND date_performed >= ? AND date_performed <= ? group by 1,2,3 ORDER BY 1;", start, fin]).each{|x|
#     # having SUM( duration ) > workers.ceiling_hours
#     w = Worker.find(x["id"])
#     t = x["actual"].to_f
#     for i in holidays
#       t += w.holiday_credit_per_day(i)
#     end
#     data +=  "#{x["worker"]}, who's ceiling is #{x["ceiling"]}, worked #{t} hours\n" if t > x["ceiling"].to_f
#   }
# }
# Notifier.deliver_text_report("management_mailing_list", "Overtime Report", data)
