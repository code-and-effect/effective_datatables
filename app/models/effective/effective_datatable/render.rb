# This is extended as class level into Datatable

module Effective
  module EffectiveDatatable
    module Render
      BLANK = ''.freeze

      private

      # So the idea here is that we want to do as much as possible on the database in ActiveRecord
      # And then run any array_columns through in post-processed results
      def table_data
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
        # TODO

        # Format all results
        format(col)

        # Finalize hook
        finalize(col)
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

      def format(collection)
        # We want to use the render :collection for each column that renders partials
        rendered = {}

        columns.each do |name, opts|
          if opts[:partial] && state[:visible][name]
            locals = {
              datatable: self,
              column: columns[name],
              controller_namespace: controller_namespace
            }.merge(actions_col_locals(opts)).merge(resource_col_locals(opts))

            rendered[name] = (view.render(
              partial: opts[:partial],
              as: :resource,
              collection: collection.map { |row| row[opts[:index]] },
              formats: :html,
              locals: locals,
              spacer_template: '/effective/datatables/spacer_template',
            ) || '').split('EFFECTIVEDATATABLESSPACER')
          end
        end

        collection.each_with_index do |row, row_index|
          columns.each do |name, opts|
            next unless state[:visible][name]

            index = opts[:index]
            value = row[index]

            row[index] = (
              if opts[:format] && opts[:as] == :actions
                result = dsl_tool.instance_exec(value, row, &opts[:format])
                "#{rendered[name][row_index]}#{result}"
              elsif opts[:format]
                dsl_tool.instance_exec(value, row, &opts[:format])
              elsif opts[:partial]
                rendered[name][row_index]
              else
                format_column(value, opts)
              end
            )
          end
        end
      end

      def format_column(value, column)
        case column[:as]
        when :effective_obfuscation
          value
        when :effective_roles
          value.join(', ')
        when :datetime
          value.strftime(EffectiveDatatables.datetime_format) rescue BLANK
        when :date
          value.strftime(EffectiveDatatables.date_format) rescue BLANK
        when :price
          raise 'column type: price expects an Integer representing the number of cents' unless value.kind_of?(Integer)
          view.number_to_currency(value / 100.0) if value.present?
        when :currency
          view.number_to_currency(value) if value.present?
        when :duration
          view.number_to_duration(value) if value.present?
        when :decimal
          value
        when :percentage
          if value.present?
            value.kind_of?(Integer) ? "#{value}%" : view.number_to_percentage(value, precision: 2)
          end
        when :integer
          value
        when :boolean
          case value
          when true   ; 'Yes'
          when false  ; 'No'
          when String ; value
          end
        else
          value.to_s
        end
      end

      def aggregate(collection)
        cols = collection.transpose

        _aggregates.map do |_, aggregate|
          columns.map do |name, opts|
            next if state[:visible][name] == false

            values = cols[opts[:index]]

            if aggregate[:compute]
              dsl_tool.instance_exec(values, columns[name], &aggregate[:compute])
            else
              format_column(aggregate_column(values, opts, aggregate), opts)
            end
          end.compact
        end
      end

      def aggregate_column(values, column, aggregate)
        labeled = false

        case aggregate[:name]
        when :total
          values = values.reject { |value| value.nil? }

          if [:bulk_actions, :actions].include?(column[:as]) || values.length == 0
            BLANK
          elsif values.all? { |value| value.kind_of?(Numeric) }
            values.sum
          elsif values.all? { |value| value == true || value == false }
            "#{values.count { |val| val == true }} / #{values.count { |val| val == false}}"
          elsif !labeled
            labeled = aggregate[:label]
          elsif values.any? { |value| value.kind_of?(String) == false }
            "#{values.flatten.count} total"
          else
            BLANK
          end
        when :average
          values = values.map { |value| value.presence || 0 }

          if values.all? { |value| value.kind_of?(Numeric) }
            values.sum / [values.length, 1].max
          elsif column[:index] == 0
            aggregate[:label]
          else
            '-'
          end
        else
          raise 'not implemented'
        end
      end

      def actions_col_locals(opts)
        return {} unless opts[:as] == :actions && active_record_collection?

        locals = {}

        locals[:show_action] = opts[:show]
        locals[:edit_action] = opts[:edit]
        locals[:destroy_action] = opts[:destroy]

        if locals[:show_action] && (EffectiveDatatables.authorized?(view.controller, :show, collection_class) rescue false)
          locals[:show_path] = resource.show_path(check: true)
        else
          locals[:show_path] = false
        end

        if locals[:edit_action] && (EffectiveDatatables.authorized?(view.controller, :edit, collection_class) rescue false)
          locals[:edit_path] = resource.edit_path(check: true)
        else
          locals[:edit_path] = false
        end

        if locals[:destroy_action] && (EffectiveDatatables.authorized?(view.controller, :destroy, collection_class) rescue false)
          locals[:destroy_path] = resource.destroy_path(check: true)
        else
          locals[:destroy_path] = false
        end

        locals
      end

      def resource_col_locals(opts)
        return {} unless (resource = opts[:resource]).present?

        locals = {name: opts[:name], macro: opts[:as], show_path: false, edit_path: false}

        case opts[:action]
        when :edit
          if (EffectiveDatatables.authorized?(view.controller, :edit, resource.klass) rescue false)
            locals[:edit_path] = resource.edit_path(check: true)
          end
        when :show
          if (EffectiveDatatables.authorized?(view.controller, :show, resource.klass) rescue false)
            locals[:show_path] = resource.show_path(check: true)
          end
        when false
          # Nothing
        else
          # Fallback to defaults - check edit then show
          if (EffectiveDatatables.authorized?(view.controller, :edit, resource.klass) rescue false)
            locals[:edit_path] = resource.edit_path(check: true)
          elsif (EffectiveDatatables.authorized?(view.controller, :show, resource.klass) rescue false)
            locals[:show_path] = resource.show(check: true)
          end
        end

        locals
      end

    end # / Rendering
  end
end
