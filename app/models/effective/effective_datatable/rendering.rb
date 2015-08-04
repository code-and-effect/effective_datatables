# This is extended as class level into Datatable

module Effective
  module EffectiveDatatable
    module Rendering

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
              self.display_records = (collection_class.connection.execute("SELECT COUNT(*) FROM (#{col_sql}) AS datatables_filtered_count").first['count'] rescue 1).to_i
            else
              self.display_records = (collection_class.connection.execute("SELECT COUNT(*) FROM (#{col.to_sql}) AS datatables_filtered_count").first['count'] rescue 1).to_i
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
              destroy_action: (opts[:partial_locals] || {})[:destroy_action]
            }
            locals.merge!(opts[:partial_locals]) if opts[:partial_locals]

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
              ''
            elsif opts[:partial]
              rendered[name][index]
            elsif opts[:block]
              view.instance_exec(obj, collection, self, &opts[:block])
            elsif opts[:proc]
              view.instance_exec(obj, collection, self, &opts[:proc])
            elsif opts[:type] == :belongs_to
              (obj.send(name) rescue nil).to_s
            elsif opts[:type] == :has_many
              objs = (obj.send(name).map(&:to_s).sort rescue [])
              objs.length == 1 ? objs.first : (opts[:sentence] ? objs.to_sentence : objs.join('<br>'))
            elsif opts[:type] == :obfuscated_id
              (obj.send(:to_param) rescue nil).to_s
            elsif opts[:type] == :effective_roles
              (obj.send(:roles) rescue []).join(', ')
            elsif opts[:type] == :datetime
              (obj.send(name).strftime(EffectiveDatatables.datetime_format) rescue nil)
            elsif opts[:type] == :date
              (obj.send(name).strftime(EffectiveDatatables.date_format) rescue nil)
            else
              obj.send(name) rescue (obj[opts[:array_index]] rescue nil)
            end

          end
        end
      end

    end # / Rendering
  end
end
