# frozen_string_literal: true

module Effective
  module EffectiveDatatable
    module Dsl
      module Datatable
        # Instance Methods inside the datatable do .. end block
        def length(length)
          raise 'length must be 5, 10, 25, 50, 100, 250, 500, :all' unless [5, 10, 25, 50, 100, 250, 500, :all].include?(length)
          datatable.state[:length] ||= (length == :all ? 9999999 : length)
        end

        def order(name, dir = nil)
          raise 'order direction must be :asc or :desc' unless [nil, :asc, :desc].include?(dir)

          datatable.state[:order_name] ||= name
          datatable.state[:order_dir] ||= dir
        end

        def reorder(name, dir = nil)
          raise 'order direction must be :asc or :desc' unless [nil, :asc, :desc].include?(dir)

          datatable.state[:order_name] = :_reorder
          datatable.state[:order_dir] = dir

          reorder_col(name)
        end

        def download(bool)
          datatable.attributes[:downloadable] = bool
        end

        def skip_save_state!
          datatable.attributes[:skip_save_state] = true
        end

        # A col has its internal values sorted/searched before the block is run
        # Anything done in the block, is purely a format on the after sorted/ordered value
        # the original object == the computed value, which is yielded to the format block
        # You can't do compute with .col
        def col(name, action: nil, as: nil, col_class: nil, csv: true, label: nil, partial: nil, partial_as: nil, responsive: 10000, search: {}, sort: true, sql_column: nil, th: nil, th_append: nil, visible: true, &format)
          raise 'You cannot use partial: ... with the block syntax' if partial && block_given?

          name = name.to_sym unless name.to_s.include?('.')

          datatable._columns[name] = Effective::DatatableColumn.new(
            action: action,
            as: as,
            compute: nil,
            col_class: col_class,
            csv: csv,
            format: (format if block_given?),
            index: nil,
            label: label,
            name: name,
            partial: partial,
            partial_as: partial_as,
            responsive: responsive,
            search: search,
            sort: sort,
            sql_column: sql_column,
            th: th,
            th_append: th_append,
            visible: visible,
          )
        end

        # A val is a computed value that is then sorted/searched after the block is run
        # You can have another block by calling .format afterwards to work on the computed value itself
        def val(name, action: nil, as: nil, col_class: nil, csv: true, label: nil, partial: nil, partial_as: nil, responsive: 10000, search: {}, sort: true, sql_column: false, th: nil, th_append: nil, visible: true, &compute)
          raise 'You cannot use partial: ... with the block syntax' if partial && block_given?

          name = name.to_sym unless name.to_s.include?('.')

          datatable._columns[name] = Effective::DatatableColumn.new(
            action: action,
            as: as,
            compute: (compute if block_given?),
            col_class: col_class,
            csv: csv,
            format: nil,
            index: nil,
            label: label,
            name: name,
            partial: partial,
            partial_as: partial_as,
            responsive: responsive,
            search: search,
            sort: sort,
            sql_column: (block_given? ? false : sql_column),
            th: th,
            th_append: th_append,
            visible: visible,
          )
        end

        def actions_col(btn_class: nil, col_class: nil, partial: nil, partial_as: nil, actions_partial: nil, responsive: 5000, visible: true, **actions, &format)
          raise 'You can only have one actions column' if datatable.columns[:_actions].present?

          datatable._columns[:_actions] = Effective::DatatableColumn.new(
            action: false,
            as: :actions,
            compute: nil,
            btn_class: (btn_class || 'btn-sm btn-outline-primary'),
            col_class: col_class,
            csv: false,
            format: (format if block_given?),
            index: nil,
            label: false,
            name: :actions,
            partial: partial,
            partial_as: partial_as,
            actions_partial: (actions_partial || :dropleft),
            responsive: responsive,
            search: false,
            sort: false,
            sql_column: nil,
            th: nil,
            th_append: nil,
            visible: visible,

            # { approve: false }. These args are passed to effective_resources render_resource_actions
            actions: actions
          )
        end

        def aggregate(name, label: nil, &compute)
          datatable._aggregates[name.to_sym] = {
            compute: (compute if block_given?),
            label: label || name.to_s.titleize,
            name: name.to_sym,
          }
        end

        # Called automatically after bulk_actions do ... end
        # Call again if you want to change the position of the bulk_actions_col
        def bulk_actions_col(col_class: nil, input_name: nil, partial: nil, partial_as: nil, responsive: 5000)
          datatable._columns.delete(:_bulk_actions) if datatable.columns[:_bulk_actions]

          datatable._columns[:_bulk_actions] = Effective::DatatableColumn.new(
            action: false,
            as: :bulk_actions,
            compute: nil,
            col_class: col_class,
            csv: false,
            format: nil,
            index: nil,
            input_name: (input_name || 'bulk_actions_resources'),
            label: false,
            name: :bulk_actions,
            partial: partial || '/effective/datatables/bulk_actions_column',
            partial_as: partial_as,
            responsive: responsive,
            search: { as: :bulk_actions },
            sort: false,
            sql_column: nil,
            th: nil,
            th_append: nil,
            visible: true,
          )
        end

        # Called automatically after reorder
        # Call again if you want to change the position of the reorder_col
        def reorder_col(name, col_class: nil, partial: nil, partial_as: nil, sql_column: nil, responsive: 5000)
          datatable._columns.delete(:_reorder) if datatable.columns[:_reorder]

          datatable._columns[:_reorder] = Effective::DatatableColumn.new(
            action: false,
            as: :reorder,
            compute: nil,
            col_class: col_class,
            csv: false,
            format: nil,
            index: nil,
            label: false,
            name: :reorder,
            partial: partial || '/effective/datatables/reorder_column',
            partial_as: partial_as,
            reorder: name,
            responsive: responsive,
            search: false,
            sort: true,
            sql_column: (sql_column || name),
            th: nil,
            th_append: nil,
            visible: false
          )
        end

      end
    end
  end
end
