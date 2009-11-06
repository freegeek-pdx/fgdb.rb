# http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=511860
module ActiveRecord
  module ConnectionAdapters # :nodoc:
    module SchemaStatements
      def type_to_sql(type, limit = nil, precision = nil, scale = nil) #:nodoc:
        if native = native_database_types[type]
          column_type_sql = (native.is_a?(Hash) ? native[:name] : native).dup

          if type == :decimal # ignore limit, use precision and scale
            scale ||= native[:scale]

            if precision ||= native[:precision]
              if scale
                column_type_sql << "(#{precision},#{scale})"
              else
                column_type_sql << "(#{precision})"
              end
            elsif scale
              raise ArgumentError, "Error adding decimal column: precision cannot be empty if scale if specified"
            end

          elsif limit ||= native.is_a?(Hash) && native[:limit]
            column_type_sql << "(#{limit})"
          end

          column_type_sql
        else
          type
        end
      end
    end
  end
end

