module Effective
  module EffectiveDatatable
    module Format
      BLANK = ''.freeze

      private

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
              as: (opts[:partial_as] || :resource),
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
        when :boolean
          case value
          when true   ; 'Yes'
          when false  ; 'No'
          when String ; value
          end
        when :currency
          view.number_to_currency(value) if value.present?
        when :date
          (value.strftime('%F') rescue BLANK) if value.present?
        when :datetime
          (value.strftime('%F %H:%M') rescue BLANK) if value.present?
        when :decimal
          value
        when :duration
          view.number_to_duration(value) if value.present?
        when :effective_addresses
          value.to_html if value.present?
        when :effective_obfuscation
          value
        when :effective_roles
          value.join(', ')
        when :email
          view.mail_to(value) if value.present?
        when :integer
          value
        when :percentage
          case value
          when Integer    ; "#{value}%"
          when Numeric    ; view.number_to_percentage(value * 100, precision: 2)
          when String     ; value
          end
        when :price
          raise 'column type: price expects an Integer representing the number of cents' unless value.kind_of?(Integer)
          view.number_to_currency(value / 100.0) if value.present?
        else
          value.to_s
        end
      end

      def actions_col_locals(opts)
        return {} unless opts[:as] == :actions
        return { show_path: false, edit_path: false, destroy_path: false } unless active_record_collection?

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

        locals = { name: opts[:name], macro: opts[:as], show_path: false, edit_path: false }

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
