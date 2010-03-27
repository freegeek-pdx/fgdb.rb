module ActiveRecord::Validations::ClassMethods
      def validates_length_of(*attrs)
        # Merge given options with defaults.
        options = {
          :too_long     => ActiveRecord::Errors.default_error_messages[:too_long],
          :too_short    => ActiveRecord::Errors.default_error_messages[:too_short],
          :wrong_length => ActiveRecord::Errors.default_error_messages[:wrong_length]
        }.merge(DEFAULT_VALIDATION_OPTIONS)
        options.update(attrs.extract_options!.symbolize_keys)

        # Ensure that one and only one range option is specified.
        range_options = ALL_RANGE_OPTIONS & options.keys
        case range_options.size
          when 0
            raise ArgumentError, 'Range unspecified.  Specify the :within, :maximum, :minimum, or :is option.'
          when 1
            # Valid number of options; do nothing.
          else
            raise ArgumentError, 'Too many range options specified.  Choose only one.'
        end

        # Get range option and value.
        option = range_options.first
        option_value = options[range_options.first]

        case option
          when :within, :in
            raise ArgumentError, ":#{option} must be a Range" unless option_value.is_a?(Range)

            too_short = options[:too_short] % option_value.begin
            too_long  = options[:too_long]  % option_value.end

            validates_each(attrs, options) do |record, attr, value|
	      value = value.to_s if value.kind_of?(NilClass)
              value = value.split(//) if value.kind_of?(String)
              if value.size < option_value.begin
                record.errors.add(attr, too_short)
              elsif value.size > option_value.end
                record.errors.add(attr, too_long)
              end
            end
          when :is, :minimum, :maximum
            raise ArgumentError, ":#{option} must be a nonnegative Integer" unless option_value.is_a?(Integer) and option_value >= 0

            # Declare different validations per option.
            validity_checks = { :is => "==", :minimum => ">=", :maximum => "<=" }
            message_options = { :is => :wrong_length, :minimum => :too_short, :maximum => :too_long }

            message = (options[:message] || options[message_options[option]]) % option_value

            validates_each(attrs, options) do |record, attr, value|
	      value = value.to_s if value.kind_of?(NilClass)
              value = value.split(//) if value.kind_of?(String)
              record.errors.add(attr, message) unless value.size.method(validity_checks[option])[option_value]
            end
        end
      end
end
