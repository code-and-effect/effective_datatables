module Effective
  module EffectiveDatatable
    module Dsl
      module Datatable
        # Instance Methods inside the datatable do .. end block
        def order(name, dir = nil)
          raise 'order direction must be :asc or :desc' unless [nil, :asc, :desc].include?(dir)

          datatable.state[:order_name] ||= name
          datatable.state[:order_dir] ||= dir
        end

        def length(length)
          raise 'length must be 5, 10, 25, 50, 100, 250, 500, :all' unless [5, 10, 25, 50, 100, 250, 500, :all].include?(length)
          datatable.state[:length] ||= (length == :all ? 9999999 : length)
        end

        # A col has its internal values sorted/searched before the block is run
        # Anything done in the block, is purely a format on the after sorted/ordered value
        # the original object == the computed value, which is yielded to the format block
        # You can't do compute with .col
        def col(name, action: nil, as: nil, col_class: nil, label: nil, partial: nil, partial_as: nil, responsive: 10000, search: {}, sort: true, sql_column: nil, th: nil, th_append: nil, visible: true, &format)
          raise 'You cannot use partial: ... with the block syntax' if partial && block_given?

          name = name.to_sym unless name.to_s.include?('.')

          datatable._columns[name] = Effective::DatatableColumn.new(
            action: action,  # resource columns only
            as: as,
            compute: nil,
            col_class: col_class,
            format: (format if block_given?),
            index: nil,
            label: label || name.to_s.split('.').last.titleize,
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
        def val(name, action: nil, as: nil, col_class: nil, label: nil, partial: nil, partial_as: nil, responsive: 10000, search: {}, sort: true, sql_column: false, th: nil, th_append: nil, visible: true, &compute)
          raise 'You cannot use partial: ... with the block syntax' if partial && block_given?

          name = name.to_sym unless name.to_s.include?('.')

          datatable._columns[name] = Effective::DatatableColumn.new(
            action: action, # Resource columns only
            as: as,
            compute: (compute if block_given?),
            col_class: col_class,
            format: nil,
            index: nil,
            label: label || name.to_s.split('.').last.titleize,
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

        def bulk_actions_col(col_class: nil, partial: nil, partial_as: nil, responsive: 5000)
          raise 'You can only have one bulk actions column' if datatable.columns[:_bulk_actions].present?

          datatable._columns[:_bulk_actions] = Effective::DatatableColumn.new(
            action: false,
            as: :bulk_actions,
            compute: nil,
            col_class: col_class,
            format: nil,
            index: nil,
            label: '',
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

        def actions_col(show: true, edit: true, destroy: true, col_class: nil, partial: nil, partial_as: nil, responsive: 5000, visible: true, &format)
          raise 'You can only have one actions column' if datatable.columns[:_actions].present?

          datatable._columns[:_actions] = Effective::DatatableColumn.new(
            action: false,
            as: :actions,
            compute: nil,
            col_class: col_class,
            format: (format if block_given?),
            index: nil,
            label: '',
            name: :actions,
            partial: partial || '/effective/datatables/actions_column',
            partial_as: partial_as,
            responsive: responsive,
            search: false,
            sort: false,
            sql_column: nil,
            th: nil,
            th_append: nil,
            visible: visible,

            show: show,
            edit: edit,
            destroy: destroy
          )
        end

        def aggregate(name, label: nil, &compute)
          datatable._aggregates[name.to_sym] = {
            compute: (compute if block_given?),
            label: label || name.to_s.titleize,
            name: name.to_sym,
          }
        end
      end
    end
  end
end
