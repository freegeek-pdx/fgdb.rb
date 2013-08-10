class LogsController < ApplicationController
  layout :with_sidebar


  def find_deleted
    if params[:search]
      @search = OpenStruct.new()
      params[:search].each{|k,v|
        @search.send(k + "=", v)
      }
      sql = ["SELECT logs.date, logs.table_name, logs.action, logs.thing_id, users.login AS user, cashiers.login AS cashier FROM logs JOIN users ON users.id = logs.user_id JOIN users AS cashiers ON cashiers.id = logs.cashier_id WHERE action LIKE 'destroy'"]
      if params[:search][:created_before].to_s != ""
        if params[:search][:table_name] == ""
          @error = "Ignored created before condition, cannot be used without selecting a single table name"
        else
          table = params[:search][:table_name].to_s
          table = table.gsub(/[^a-z]/, "")
          sql[0] += " AND thing_id < COALESCE((SELECT min(id) FROM #{table} WHERE created_at >= ?),(SELECT max(id) FROM #{table}))"
          sql << params[:search][:created_before]
        end
      end
      if params[:search][:table_name].to_s != ""
        sql[0] += " AND table_name LIKE ?"
        sql << params[:search][:table_name]
      end
      if params[:search][:deleted_after].to_s != ""
        sql[0] += " AND date >= ?"
        sql << params[:search][:deleted_after]
      end
      sql[0] += " ORDER BY date ASC "
      # {"thing_id"=>"2178960", "action"=>"destroy", "date"=>"2009-03-27 11:01:55.581504", "cashier"=>"rich", "table_name"=>"gizmo_events", "user"=>"rich"
      @results = [["Datestamp", "Table Name", "Action", "Object ID", "User", "Cashier"]]
      @logs = Log.paginate_by_sql(sql, :page => (params[:page] || 1), :per_page => 50)
      @logs.each{|x|
        @results << [x.date, x.table_name, x.action, x.thing_id, x.user, x.cashier]
      }
    end
  end

  def index
  end

  def show_log
  end
end
