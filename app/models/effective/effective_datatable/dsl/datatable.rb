module Effective
  module EffectiveDatatable
    module Dsl
      module Datatable
        # Instance Methods inside the datatable do .. end block
        def default_order(name, direction = :asc)
          datatable.state[:order_col] ||= name
          datatable.state[:order_dir] ||= direction
        end

        def default_entries(entries)
          datatable.state[:entries] ||= entries
        end

        def table_column(name, as: nil, col_class: nil, filter: {}, format: nil, label: nil, partial: nil, responsive: 10000, sortable: true, visible: true, width: nil, &block)
          raise 'You cannot use partial: ... with the block syntax' if partial && block_given?

          datatable.columns[name] = {
            array_column: false,
            as: as,
            col_class: col_class,
            filter: filter,
            format: format,
            label: label,
            partial: partial,
            responsive: responsive,
            sortable: sortable,
            visible: visible,
            width: width
          }
        end

        def array_column(name, as: nil, col_class: nil, filter: {}, format: nil, label: nil, partial: nil, responsive: 10000, sortable: true, visible: true, width: nil, &block)
          raise 'You cannot use partial: ... with the block syntax' if partial && block_given?

          datatable.columns[name] = {
            array_column: true,
            as: as,
            col_class: col_class,
            filter: filter,
            format: format,
            label: label,
            partial: partial,
            responsive: responsive,
            sortable: sortable,
            visible: visible,
            width: with
          }
        end


        # def actions_column(options = {}, proc = nil, &block)
        #   raise 'first parameter to actions_column should be a hash' unless options.kind_of?(Hash)

        #   show = options.fetch(:show, (EffectiveDatatables.actions_column[:show] rescue false))
        #   edit = options.fetch(:edit, (EffectiveDatatables.actions_column[:edit] rescue false))
        #   destroy = options.fetch(:destroy, (EffectiveDatatables.actions_column[:destroy] rescue false))
        #   unarchive = options.fetch(:unarchive, (EffectiveDatatables.actions_column[:unarchive] rescue false))
        #   name = options.fetch(:name, 'actions')

        #   opts = {
        #     type: :actions,
        #     sortable: false,
        #     filter: false,
        #     responsivePriority: 0,
        #     partial_locals: { show_action: show, edit_action: edit, destroy_action: destroy, unarchive_action: unarchive },
        #     actions_block: block
        #   }.merge(options)

        #   opts[:partial_local] ||= :resource unless opts[:partial].present?
        #   opts[:partial] ||= '/effective/datatables/actions_column' unless proc.present?

        #   table_column(name, opts, proc)
        # end

        # def bulk_actions_column(options = {}, proc = nil, &block)
        #   raise 'first parameter to bulk_actions_column should be a hash' unless options.kind_of?(Hash)

        #   name = options.fetch(:name, 'bulk_actions')
        #   resource_method = options.fetch(:resource_method, :to_param)

        #   opts = {
        #     bulk_actions_column: true,
        #     label: '',
        #     partial_local: :resource,
        #     partial: '/effective/datatables/bulk_actions_column',
        #     partial_locals: { resource_method: resource_method },
        #     sortable: false,
        #     dropdown_partial: '/effective/datatables/bulk_actions_dropdown',
        #     dropdown_block: block
        #   }.merge(options)

        #   table_column(name, opts, proc)
        # end

        # def aggregate(name, options = {}, &block)
        #   if block_given?
        #     raise "You cannot use proc: ... with the block syntax" if options[:proc]
        #     options[:block] = block
        #   end

        #   (@aggregates ||= HashWithIndifferentAccess.new)[name] = options
        # end
      end
    end
  end
end
