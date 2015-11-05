# This is extended as class level into Datatable

module Effective
  module EffectiveDatatable
    module Rendering
      BLANK = ''.freeze

      def finalize(collection) # Override me if you like
        collection
      end

      protected

      # So the idea here is that we want to do as much as possible on the database in ActiveRecord
      # And then run any array_columns through in post-processed results
      def table_data
        col = collection

        if active_record_collection?
          col = table_tool.order(col)
          col = table_tool.search(col)

          if table_tool.search_terms.present? && array_tool.search_terms.blank?
            if collection_class.connection.respond_to?(:unprepared_statement)
              # https://github.com/rails/rails/issues/15331
              col_sql = collection_class.connection.unprepared_statement { col.to_sql }
              self.display_records = (collection_class.connection.execute("SELECT COUNT(*) FROM (#{col_sql}) AS datatables_filtered_count").first.values.first rescue 1).to_i
            else
              self.display_records = (collection_class.connection.execute("SELECT COUNT(*) FROM (#{col.to_sql}) AS datatables_filtered_count").first.values.first rescue 1).to_i
            end
          end
        end

        if array_tool.search_terms.present?
          col = self.arrayize(col)
          col = array_tool.search(col)
          self.display_records = col.size
        end

        if array_tool.order_column.present?
          col = self.arrayize(col)
          col = array_tool.order(col)
        end

        self.display_records ||= total_records

        if col.kind_of?(Array)
          col = array_tool.paginate(col)
        else
          col = table_tool.paginate(col)
          col = self.arrayize(col)
        end

        self.format(col)
        col = self.finalize(col)
      end

      def arrayize(collection)
        return collection if @arrayized  # Prevent the collection from being arrayized more than once
        @arrayized = true

        # We want to use the render :collection for each column that renders partials
        rendered = {}
        (display_table_columns || table_columns).each do |name, opts|
          if opts[:partial] && opts[:visible]
            locals = {
              datatable: self,
              table_column: table_columns[name],
              controller_namespace: view.controller_path.split('/')[0...-1].map { |path| path.downcase.to_sym if path.present? }.compact,
              show_action: (opts[:partial_locals] || {})[:show_action],
              edit_action: (opts[:partial_locals] || {})[:edit_action],
              destroy_action: (opts[:partial_locals] || {})[:destroy_action],
              unarchive_action: (opts[:partial_locals] || {})[:unarchive_action]
            }
            locals.merge!(opts[:partial_locals]) if opts[:partial_locals]

            if active_record_collection?
              if locals[:show_action] == :authorize
                locals[:show_action] = (EffectiveDatatables.authorized?(controller, :show, collection_class) rescue false)
              end

              if locals[:edit_action] == :authorize
                locals[:edit_action] = (EffectiveDatatables.authorized?(controller, :edit, collection_class) rescue false)
              end

              if locals[:destroy_action] == :authorize
                locals[:destroy_action] = (EffectiveDatatables.authorized?(controller, :destroy, collection_class) rescue false)
              end

              if locals[:unarchive_action] == :authorize
                locals[:unarchive_action] = (EffectiveDatatables.authorized?(controller, :unarchive, collection_class) rescue false)
              end
            end

            rendered[name] = (render(
              :partial => opts[:partial],
              :as => opts[:partial_local],
              :collection => collection,
              :formats => :html,
              :locals => locals,
              :spacer_template => '/effective/datatables/spacer_template',
            ) || '').split('EFFECTIVEDATATABLESSPACER')
          end
        end

        collection.each_with_index.map do |obj, index|
          (display_table_columns || table_columns).map do |name, opts|
            if opts[:visible] == false
              BLANK
            elsif opts[:partial]
              rendered[name][index]
            elsif opts[:block]
              view.instance_exec(obj, collection, self, &opts[:block])
            elsif opts[:proc]
              view.instance_exec(obj, collection, self, &opts[:proc])
            elsif opts[:type] == :belongs_to
              (obj.send(name) rescue nil)
            elsif opts[:type] == :belongs_to_polymorphic
              (obj.send(name) rescue nil)
            elsif opts[:type] == :has_many
              (obj.send(name).to_a rescue [])
            elsif opts[:type] == :obfuscated_id
              (obj.send(:to_param) rescue nil).to_s
            elsif opts[:type] == :effective_address
              (Array(obj.send(name)) rescue [])
            elsif opts[:type] == :effective_roles
              (obj.send(:roles) rescue [])
            elsif obj.kind_of?(Array) # Array backed collection
              obj[opts[:array_index]]
            else
              (obj.send(name) rescue (obj[name] rescue nil))
            end
          end
        end
      end

      def format(collection)
        collection.each do |row|
          (display_table_columns || table_columns).each_with_index do |(name, opts), index|
            value = row[index]
            next if value == nil || value == BLANK || opts[:visible] == false
            next if opts[:block] || opts[:partial] || opts[:proc]

            case opts[:type]
            when :belongs_to, :belongs_to_polymorphic
              row[index] = value.to_s
            when :has_many
              if value.kind_of?(Array)
                if value.length == 0
                  row[index] = BLANK
                elsif value.length == 1
                  row[index] = value.first.to_s
                elsif opts[:sentence]
                  row[index] = value.map { |v| v.to_s }.to_sentence
                else
                  row[index] = value.map { |v| v.to_s }.join('<br>')
                end
              end
            when :effective_address
              row[index] = value.map { |addr| addr.to_html }.join('<br>')
            when :effective_roles
              row[index] = value.join(', ')
            when :datetime
              row[index] = value.strftime(EffectiveDatatables.datetime_format) rescue BLANK
            when :date
              row[index] = value.strftime(EffectiveDatatables.date_format) rescue BLANK
            when :price
              # This is an integer value, "number of cents"
              raise 'column type: price expects an Integer representing the number of cents' unless value.kind_of?(Integer)
              row[index] = number_to_currency(value / 100.0)
            when :currency
              row[index] = number_to_currency(value || 0)
            when :integer
              if EffectiveDatatables.integer_format.kind_of?(Symbol)
                row[index] = view.instance_exec { public_send(EffectiveDatatables.integer_format, value) }
              elsif EffectiveDatatables.integer_format.respond_to?(:call)
                row[index] = view.instance_exec { EffectiveDatatables.integer_format.call(value) }
              end
            when :boolean
              if EffectiveDatatables.boolean_format == :yes_no && value == true
                row[index] = 'Yes'
              elsif EffectiveDatatables.boolean_format == :yes_no && value == false
                row[index] = 'No'
              end
            when :string
              row[index] = mail_to(value) if name == 'email'
            else
              ; # Nothing
            end
          end
        end

        collection
      end

    end # / Rendering
  end
end
