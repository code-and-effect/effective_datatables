# frozen_string_literal: true

module Effective
  module EffectiveDatatable
    module Format
      BLANK = ''.freeze
      NONVISIBLE = '...'.freeze
      SPACER = 'EFFECTIVEDATATABLESSPACER'.freeze
      SPACER_TEMPLATE = '/effective/datatables/spacer_template'.freeze

      private

      def format(collection, csv: false)
        # We want to use the render :collection for each column that renders partials
        rendered = {}

        columns.each do |name, opts|
          if state[:visible][name] == false && !csv
            # Nothing to do
          elsif csv && !opts[:csv]
            # Nothing to do
          elsif opts[:partial]
            locals = { datatable: self, column: opts }.merge!(resource_col_locals(opts))

            rendered[name] = (view.render(
              partial: opts[:partial],
              as: (opts[:partial_as] || :resource),
              collection: collection.map { |row| row[opts[:index]] },
              formats: :html,
              locals: locals,
              spacer_template: SPACER_TEMPLATE
            ) || '').split(SPACER)

          elsif opts[:as] == :actions # This is actions_col and actions_col do .. end, but not actions_col partial: 'something'
            locals = { datatable: self, column: opts, spacer_template: SPACER_TEMPLATE }

            atts = {
              actions: actions_col_actions(opts),
              btn_class: opts[:btn_class],
              effective_resource: effective_resource,
              locals: locals,
              partial: opts[:actions_partial],
            }.merge!(opts[:actions]).tap(&:compact!)

            rendered[name] = if effective_resource.blank?
              collection.map { |row| row[opts[:index]] }.map do |resource|
                polymorphic_resource = Effective::Resource.new(resource, namespace: controller_namespace)
                (view.render_resource_actions(resource, atts.merge(effective_resource: polymorphic_resource), &opts[:format]) || '')
              end
            else
              (view.render_resource_actions(collection.map { |row| row[opts[:index]] }, atts, &opts[:format]) || '').split(SPACER)
            end
          end
        end

        collection.each_with_index do |row, row_index|
          columns.each do |name, opts|
            index = opts[:index]
            value = row[index]

            formatted = (
              if state[:visible][name] == false && !csv
                NONVISIBLE
              elsif csv && !opts[:csv]
                BLANK
              elsif opts[:as] == :actions
                rendered[name][row_index]
              elsif opts[:format] && rendered.key?(name)
                dsl_tool.instance_exec(value, row, rendered[name][row_index], &opts[:format])
              elsif opts[:format]
                dsl_tool.instance_exec(value, row, &opts[:format])
              elsif opts[:partial]
                rendered[name][row_index]
              else
                format_column(value, opts, csv: csv)
              end
            )

            if csv && (opts[:format] || opts[:partial])
              formatted = view.strip_tags(formatted)

              formatted.gsub!("\n\n", ' ') unless formatted.frozen?
              formatted.gsub!("\n", '')  unless formatted.frozen?
            end

            row[index] = formatted
          end
        end
      end

      def format_column(value, column, csv: false)
        return if value.nil? || (column[:resource] && value.blank?)

        unless column[:as] == :email
          return value if value.kind_of?(String)
        end

        if value.kind_of?(Array) && column[:as] == :string
          return value.map { |v| view.content_tag(:div, format_column(v, column, csv: csv), class: 'col-resource_item') }.join.html_safe
        end

        case column[:as]
        when :actions
          raise("please use actions_col instead of col(#{name}, as: :actions)")
        when :boolean
          view.t("effective_datatables.boolean_#{value}")
        when :currency
          view.number_to_currency(value)
        when :date
          value.respond_to?(:strftime) ? value.strftime(EffectiveDatatables.format_date) : BLANK
        when :datetime
          if csv
            value
          else
            value.respond_to?(:strftime) ? value.strftime(EffectiveDatatables.format_datetime) : BLANK
          end
        when :decimal
          value
        when :duration
          view.number_to_duration(value)
        when :effective_addresses
          value.to_html
        when :effective_obfuscation
          value
        when :effective_roles
          value.join(', ')
        when :email
          csv ? value : view.mail_to(value)
        when :integer
          value
        when :percent
          case value
          when Integer    ; view.number_to_percentage(value / 1000.0, precision: 3).gsub('.000%', '%')
          when Numeric    ; view.number_to_percentage(value, precision: 3).gsub('.000%', '%')
          end
        when :price
          case value
          when Integer    ; view.number_to_currency(value / 100.0) # an Integer representing the number of cents
          when Numeric    ; view.number_to_currency(value)
          end
        when :time
          value.respond_to?(:strftime) ? value.strftime(EffectiveDatatables.format_time) : BLANK
        else
          value.to_s
        end
      end

      # Takes all default resource actions
      # Applies data-remote to anything that's data-method post or delete
      # Merges in any extra attributes when passed as a Hash
      def actions_col_actions(column)
        resource_actions = (effective_resource&.resource_actions || fallback_effective_resource.fallback_resource_actions)

        actions = if column[:inline]
          resource_actions.transform_values { |opts| opts['data-remote'] = true; opts }
        else
          resource_actions.transform_values { |opts| opts['data-remote'] = true if opts['data-method']; opts }
        end

        # Merge local options. Special behaviour for remote: false
        if column[:actions].present? && column[:actions].kind_of?(Hash)
          column[:actions].each do |action, opts|
            next unless opts.kind_of?(Hash)

            existing = actions.find { |_, v| v[:action] == action }&.first
            next unless existing.present?

            actions[existing]['data-remote'] = opts[:remote] if opts.key?(:remote)
            actions[existing]['data-remote'] = opts['remote'] if opts.key?('remote')

            actions[existing].merge!(opts.except(:remote, 'remote'))
          end

          actions = actions.sort do |(_, a), (_, b)|
            (column[:actions].keys.index(a[:action]) || 99) <=> (column[:actions].keys.index(b[:action]) || 99)
          end.to_h

        end

        actions
      end

      def resource_col_locals(opts)
        return {} unless (associated_resource = opts[:resource]).present?

        associated = associated_resource.macros.include?(opts[:as])
        polymorphic = (opts[:as] == :belongs_to_polymorphic)

        resource_name = opts[:name] if associated
        resource_to_s = opts[:name] unless associated || array_collection?

        locals = {
          resource_name: resource_name,
          resource_to_s: resource_to_s,
          effective_resource: associated_resource,
          show_action: false,
          edit_action: false
        }

        case opts[:action]
        when :edit
          locals[:edit_action] = (polymorphic || associated_resource.routes[:edit].present?)
        when :show
          locals[:show_action] = (polymorphic || associated_resource.routes[:show].present?)
        when false
          # Nothing. Already false.
        else
          locals[:edit_action] = (polymorphic || associated_resource.routes[:edit].present?)
          locals[:show_action] = (polymorphic || associated_resource.routes[:show].present?)
        end

        locals
      end

    end # / Rendering
  end
end
