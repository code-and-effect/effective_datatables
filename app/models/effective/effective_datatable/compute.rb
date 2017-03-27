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
        @display_records = column_tool.size(col) unless value_tool.searched.present?

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
      end

      def arrayize(collection)
        return collection if @arrayized  # Prevent the collection from being arrayized more than once
        @arrayized = true

        collection.map do |obj|
          columns.map do |name, opts|
            if state[:visible][name] == false && (name != order_name)  # Sort by invisible array column
              BLANK
            elsif opts[:partial] || (opts[:format] && !opts[:compute])
              active_record_collection? ? obj : obj[opts[:index]]
            elsif opts[:compute]
              if active_record_collection?
                dsl_tool.instance_exec(obj, collection, &opts[:compute])
              else
                dsl_tool.instance_exec(obj, obj[opts[:index]], &opts[:compute])
              end
            elsif opts[:as] == :effective_obfuscation
              obj.to_param
            elsif array_collection?
              obj[opts[:index]]
            elsif opts[:sql_as_column]
              obj[name] || obj.send(name)
            else
              obj.send(name)
            end
          end
        end
      end

      def aggregate(collection)
        cols = collection.transpose

        _aggregates.map do |_, aggregate|
          columns.map do |name, opts|
            next if state[:visible][name] == false && datatables_ajax_request?

            values = cols[opts[:index]]

            if state[:visible][name] == false
              BLANK
            elsif aggregate[:compute]
              dsl_tool.instance_exec(values, columns[name], &aggregate[:compute])
            else
              format_column(aggregate_column(values, opts, aggregate), opts)
            end
          end.compact
        end
      end

      def aggregate_column(values, column, aggregate)
        labeled = false
        length = values.length
        values = values.reject { |value| value.nil? }

        if [:bulk_actions, :actions].include?(column[:as]) || length == 0
          return BLANK
        end

        case aggregate[:name]
        when :total
          if values.all? { |value| value.kind_of?(Numeric) }
            values.sum
          elsif values.all? { |value| value == true || value == false }
            "#{values.count { |val| val == true }} / #{values.count { |val| val == false}}"
          elsif !labeled
            labeled = aggregate[:label]
          elsif values.any? { |value| value.kind_of?(String) == false }
            "#{values.flatten.count} total"
          end
        when :average
          if values.all? { |value| value.kind_of?(Numeric) }
            values.sum / [length, 1].max
          elsif values.all? { |value| value == true || value == false }
            values.count { |val| val == true } >= (length / 2) ? true : false
          elsif !labeled
            labeled = aggregate[:label]
          elsif values.any? { |value| value.kind_of?(String) == false }
            '-'
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
            raise "expected chart #{name} block to return an Array of Arrays"
          end

          retval
        end
      end

    end
  end
end
