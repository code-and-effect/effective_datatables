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
            if state[:visible][name] == false && (name != order_name.to_s)  # Sort by invisible array column
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
            }.merge(actions_col_locals(opts))

            rendered[name] = dsl_tool.render(
              partial: opts[:partial],
              as: :resource,
              collection: collection.map { |row| row[opts[:index]] },
              formats: :html,
              locals: locals,
              spacer_template: '/effective/datatables/spacer_template',
            ).split('EFFECTIVEDATATABLESSPACER')
          end
        end

        collection.each_with_index do |row, row_index|
          columns.each do |name, opts|
            next if state[:visible][name] == false

            index = opts[:index]
            value = row[index]

            row[index] = (
              if opts[:partial]
                rendered[name][row_index]
              elsif opts[:format]
                dsl_tool.instance_exec(*value, row, &opts[:format])
              elsif opts[:as] == :belongs_to
                value.to_s
              elsif opts[:as] == :has_many
                value.map { |v| v.to_s }.join('<br>')
              elsif opts[:as] == :effective_addresses
                value.map { |addr| addr.to_html }.join('<br>')
              elsif opts[:as] == :effective_obfuscation
                value
              elsif opts[:as] == :effective_roles
                value.join(', ')
              elsif opts[:as] == :datetime
                value.strftime(EffectiveDatatables.datetime_format) rescue BLANK
              elsif opts[:as] == :date
                value.strftime(EffectiveDatatables.date_format) rescue BLANK
              elsif opts[:as] == :price
                raise 'column type: price expects an Integer representing the number of cents' unless value.kind_of?(Integer)
                number_to_currency(value / 100.0)
              elsif opts[:as] == :currency
                number_to_currency(value || 0)
              elsif opts[:as] == :decimal
                value
              elsif opts[:as] == :percentage
                number_to_percentage(value || 0)
              elsif opts[:as] == :integer
                #EffectiveDatatables.integer_format.send(value)
                value
              elsif opts[:as] == :boolean
                value == true ? 'Yes' : 'No'
              elsif opts[:as] == :string
                value
              else
                raise "unsupported type '#{opts[:as]}' for column #{name}"
              end
            )
          end
        end
      end


      # def arrayize22(collection)
      #   return collection if @arrayized  # Prevent the collection from being arrayized more than once
      #   @arrayized = true

      #   # We want to use the render :collection for each column that renders partials
      #   rendered = {}

      #   columns.each do |name, opts|
      #     if opts[:partial] && state[:visible][name]
      #       locals = {
      #         datatable: self,
      #         column: columns[name],
      #         controller_namespace: controller_namespace
      #       }.merge(actions_col_locals(opts))

      #       rendered[name] = view.render(
      #         partial: opts[:partial],
      #         as: :resource,
      #         collection: collection,
      #         formats: :html,
      #         locals: locals,
      #         spacer_template: '/effective/datatables/spacer_template',
      #       ).split('EFFECTIVEDATATABLESSPACER')
      #     end
      #   end

      #   collection.each_with_index.map do |obj, index|
      #     columns.map do |name, opts|
      #       begin
      #         if state[:visible][name] == false && (name != order_name.to_s) # Sort by invisible array column
      #           BLANK
      #         elsif opts[:block]
      #           result = if active_record_collection?
      #             view.instance_exec(obj, collection, self, &opts[:block])
      #           else
      #             view.instance_exec(obj, obj[opts[:index]], collection, self, &opts[:block])
      #           end

      #           opts[:as] == :actions ? (rendered[name][index] + result) : result
      #         elsif opts[:partial]
      #           rendered[name][index]
      #         elsif opts[:as] == :belongs_to
      #           (obj.send(name) rescue nil).to_s
      #         elsif opts[:as] == :belongs_to_polymorphic
      #           (obj.send(name) rescue nil).to_s
      #         elsif opts[:as] == :has_many
      #           (obj.send(name).map { |obj| obj.to_s }.join('<br>') rescue BLANK)
      #         elsif opts[:as] == :has_and_belongs_to_many
      #           (obj.send(name).map { |obj| obj.to_s }.join('<br>') rescue BLANK)
      #         elsif opts[:as] == :bulk_actions
      #           BLANK
      #         elsif opts[:as] == :year
      #           obj.send(name).try(:year)
      #         elsif opts[:as] == :obfuscated_id
      #           (obj.send(:to_param) rescue nil).to_s
      #         elsif opts[:as] == :effective_address
      #           (Array(obj.send(name)) rescue [])
      #         elsif opts[:as] == :effective_roles
      #           (obj.send(:roles) rescue [])
      #         elsif obj.kind_of?(Array) # Array backed collection
      #           obj[opts[:index]]
      #         elsif opts[:sql_as_column]
      #           obj[name] || obj.send(name)
      #         else
      #           obj.send(name)
      #         end
      #       rescue => e
      #         Rails.env.production? ? obj.try(:[], name) : raise(e)
      #       end
      #     end
      #   end
      # end

      # def format22(collection)
      #   collection.each do |row|
      #     columns.each_with_index do |(name, opts), index|
      #       value = row[index]
      #       next if value == nil || value == BLANK || state[:visible][name] == false
      #       next if opts[:block] || opts[:partial]

      #       if opts[:sql_as_column]
      #         row[index] = value.to_s
      #       end

      #       case (opts[:format] || opts[:as])
      #       when :belongs_to, :belongs_to_polymorphic
      #         row[index] = value.to_s
      #       when :has_many
      #         if value.kind_of?(Array)
      #           if value.length == 0
      #             row[index] = BLANK
      #           elsif value.length == 1
      #             row[index] = value.first.to_s
      #           elsif opts[:sentence]
      #             row[index] = value.map { |v| v.to_s }.to_sentence
      #           else
      #             row[index] = value.map { |v| v.to_s }.join('<br>')
      #           end
      #         end
      #       when :effective_address
      #         row[index] = value.map { |addr| addr.to_html }.join('<br>')
      #       when :effective_roles
      #         row[index] = value.join(', ')
      #       when :datetime
      #         row[index] = value.strftime(EffectiveDatatables.datetime_format) rescue BLANK
      #       when :date
      #         row[index] = value.strftime(EffectiveDatatables.date_format) rescue BLANK
      #       when :price
      #         # This is an integer value, "number of cents"
      #         raise 'column type: price expects an Integer representing the number of cents' unless value.kind_of?(Integer)
      #         row[index] = number_to_currency(value / 100.0)
      #       when :currency
      #         row[index] = number_to_currency(value || 0)
      #       when :percentage
      #         row[index] = number_to_percentage(value || 0)
      #       when :integer
      #         if EffectiveDatatables.integer_format.kind_of?(Symbol)
      #           row[index] = view.instance_exec { public_send(EffectiveDatatables.integer_format, value) }
      #         elsif EffectiveDatatables.integer_format.respond_to?(:call)
      #           row[index] = view.instance_exec { EffectiveDatatables.integer_format.call(value) }
      #         end
      #       when :boolean
      #         if EffectiveDatatables.boolean_format == :yes_no && value == true
      #           row[index] = 'Yes'
      #         elsif EffectiveDatatables.boolean_format == :yes_no && value == false
      #           row[index] = 'No'
      #         end
      #       when :string
      #         row[index] = mail_to(value) if name == 'email'
      #       else
      #         ; # Nothing
      #       end
      #     end
      #   end

      #   collection
      # end

      # This should return an Array of values the same length as table_data
      def aggregate_data(table_data)
        return false unless aggregates.present?

        values = table_data.transpose

        aggregates.map do |name, options|
          columns.map.with_index do |(name, column), index|

            if state[:visible][name] != true
              ''
            elsif (options[:block] || options[:proc]).respond_to?(:call)
              view.instance_exec(column, (values[index] || []), values, &(options[:block] || options[:proc]))
            else
              ''
            end
          end
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

    end # / Rendering
  end
end
