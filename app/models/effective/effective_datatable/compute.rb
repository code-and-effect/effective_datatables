module Effective
  module EffectiveDatatable
    module Compute
      BLANK = ''.freeze

      private

      # So the idea here is that we want to do as much as possible on the database in ActiveRecord
      # And then run any array_columns through in post-processed results
      def compute
        col = collection

        # Assign total records
        @total_records = (active_record_collection? ? column_tool.size(col) : value_tool.size(col))

        # Apply scope
        col = column_tool.scope(col)

        # Apply column searching
        col = column_tool.search(col)

        unless value_tool.searched.present? || (column_tool.scoped.blank? && column_tool.searched.blank?)
          @display_records = column_tool.size(col)
        end

        # Apply column ordering
        col = column_tool.order(col)

        # Arrayize if we have value tool work to do
        col = arrayize(col) if value_tool.searched.present? || value_tool.ordered.present?

        # Apply value searching
        col = value_tool.search(col)
        @display_records = value_tool.size(col) if value_tool.searched.present?

        # Apply value ordering
        col = value_tool.order(col)

        # Apply pagination
        col = col.kind_of?(Array) ? value_tool.paginate(col) : column_tool.paginate(col)

        # Arrayize the searched, ordered, paginated results
        col = arrayize(col) unless col.kind_of?(Array)

        # Assign display records
        @display_records ||= @total_records

        # Compute aggregate data
        @aggregates_data = aggregate(col) if _aggregates.present?

        # Charts too
        @charts_data = chart(col) if _charts.present?

        # Format all results
        format(col)

        # Finalize hook
        finalize(col)
      end

      def arrayize(collection)
        collection.map do |obj|
          columns.map do |name, opts|
            if state[:visible][name] == false && (name != order_name)  # Sort by invisible array column
              BLANK
            elsif opts[:compute]
              dsl_tool.instance_exec(obj, (active_record_collection? ? collection : obj[opts[:index]]), &opts[:compute])
            elsif (opts[:partial] || opts[:format])
              active_record_collection? ? obj : obj[opts[:index]]
            elsif opts[:resource]
              resource = active_record_collection? ? obj : obj[opts[:index]]

              if opts[:resource_field]
                (associated, field) = name.to_s.split('.').first(2)
                values = Array(resource.send(associated)).map { |obj| obj.send(field) }.flatten.compact
                values.length == 1 ? values.first : values
              else
                resource.send(name)
              end

            elsif opts[:as] == :actions
              obj
            elsif opts[:as] == :effective_obfuscation
              obj.to_param
            elsif array_collection?
              obj[opts[:index]]
            elsif opts[:sql_as_column]
              obj[name] || (obj.send(name) if obj.respond_to?(name))
            else
              obj.send(name)
            end
          end
        end
      end

      def aggregate(collection, raw: false) # raw values
        cols = collection.transpose

        _aggregates.map do |_, aggregate|
          aggregate[:labeled] = false

          columns.map do |name, opts|
            next if state[:visible][name] == false && datatables_ajax_request?

            values = cols[opts[:index]] || []

            if state[:visible][name] == false
              BLANK
            elsif [:bulk_actions, :actions].include?(opts[:as])
              BLANK
            elsif values.length == 0
              BLANK
            elsif opts[:aggregate]
              dsl_tool.instance_exec(values, columns[name], &opts[:aggregate])
            elsif aggregate[:compute]
              dsl_tool.instance_exec(values, columns[name], &aggregate[:compute])
            elsif raw
              aggregate_column(values, opts, aggregate)
            else
              if values.all? { |v| v.kind_of?(ActiveRecord::Base) && v.respond_to?(name) }
                values = values.map { |v| (v[name] if opts[:sql_as_column]) || v.public_send(name) }
              end

              format_column(aggregate_column(values, opts, aggregate), opts)
            end || BLANK
          end.compact
        end
      end

      def aggregate_column(values, column, aggregate)
        length = values.length
        values = values.reject { |value| value.nil? }

        return BLANK if [:id, :year].include?(column[:name])

        case aggregate[:name]
        when :total
          if [:percent].include?(column[:as])
            BLANK
          elsif values.all? { |value| value.kind_of?(Numeric) }
            values.sum
          elsif values.all? { |value| value == true || value == false }
            "#{values.count { |val| val == true }} &bull; #{values.count { |val| val == false}}"
          elsif aggregate[:labeled] == false
            aggregate[:labeled] = aggregate[:label]
          end
        when :average
          if values.all? { |value| value.kind_of?(Numeric) }
            values.sum / ([length, 1].max)
          elsif values.all? { |value| value == true || value == false }
            values.count { |val| val == true } >= (length / 2) ? true : false
          elsif aggregate[:labeled] == false
            aggregate[:labeled] = aggregate[:label]
          end
        else
          raise 'not implemented'
        end || BLANK
      end

      def chart(collection)
        _charts.inject({}) do |retval, (name, chart)|
          retval[name] = {
            as: chart[:as],
            data: dsl_tool.instance_exec(collection, &chart[:compute]),
            name: chart[:name],
            options: chart[:options]
          }

          unless retval[name][:data].kind_of?(Array) && retval[name][:data].first.kind_of?(Array)
            raise "invalid chart :#{name}. The block must return an Array of Arrays"
          end

          retval
        end
      end

    end
  end
end
