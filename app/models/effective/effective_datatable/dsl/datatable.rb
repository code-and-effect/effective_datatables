module Effective
  module EffectiveDatatable
    module Dsl
      module Datatable
        # Instance Methods inside the datatable do .. end block
        def order(name, dir = :asc)
          raise 'order direction must be :asc or :desc' unless [:asc, :desc].include?(dir)

          datatable.state[:order_name] ||= name
          datatable.state[:order_dir] ||= dir
        end

        def length(length)
          raise 'length must be 10, 25, 50, 100, 250, 1000, :all' unless [10, 25, 50, 100, 250, 1000, :all].include?(length)
          datatable.state[:length] ||= (length == :all ? 9999999 : length)
        end

        def col(name, as: nil, col_class: nil, format: nil, label: nil, partial: nil, responsive: 10000, search: {}, sort: true, sql_column: nil, th: nil, th_append: nil, visible: true, width: nil, &block)
          raise 'You cannot use partial: ... with the block syntax' if partial && block_given?

          datatable.columns[name.to_sym] = {
            array_column: false,
            as: as,
            block: (block if block_given?),
            col_class: col_class,
            format: format,
            index: datatable.columns.length,
            label: label || name.to_s.titleize,
            name: name.to_sym,
            partial: partial,
            responsive: responsive,
            search: (search.kind_of?(Hash) ? search.symbolize_keys : (search == false ? false : {})),
            sort: sort,
            sql_column: sql_column,
            th: th,
            th_append: th_append,
            visible: visible,
            width: width
          }
        end

        def val(name, as: nil, col_class: nil, format: nil, label: nil, partial: nil, responsive: 10000, search: {}, sort: true, sql_column: nil, th: nil, th_append: nil, visible: true, width: nil, &block)
          raise 'You cannot use partial: ... with the block syntax' if partial && block_given?

          datatable.columns[name.to_sym] = {
            array_column: true,
            as: as,
            block: (block if block_given?),
            col_class: col_class,
            format: format,
            index: datatable.columns.length,
            label: label || name.to_s.titleize,
            name: name.to_sym,
            partial: partial,
            responsive: responsive,
            search: (search.kind_of?(Hash) ? search.symbolize_keys : (search == false ? false : {})),
            sort: sort,
            sql_column: sql_column,
            th: th,
            th_append: th_append,
            visible: visible,
            width: width
          }
        end

        def bulk_actions_col(col_class: nil, format: nil, partial: nil, responsive: 5000)
          raise 'You can only have one bulk actions column' if datatable.columns[:bulk_actions].present?

          datatable.columns[:bulk_actions] = {
            array_column: false,
            as: :bulk_actions,
            block: nil,
            col_class: col_class,
            format: format,
            index: datatable.columns.length,
            label: '',
            name: :bulk_actions,
            partial: partial || '/effective/datatables/bulk_actions_column',
            responsive: responsive,
            search: { as: :bulk_actions },
            sort: false,
            sql_column: nil,
            th: nil,
            th_append: nil,
            visible: true,
            width: nil
          }
        end

        def actions_col(show: true, edit: true, destroy: true, col_class: nil, partial: nil, responsive: 5000, &block)
          raise 'You can only have one actions column' if datatable.columns[:actions].present?

          datatable.columns[:actions] = {
            array_column: false,
            as: :actions,
            block: (block if block_given?),
            col_class: col_class,
            format: nil,
            index: datatable.columns.length,
            label: '',
            name: :actions,
            partial: partial || '/effective/datatables/actions_column',
            responsive: responsive,
            search: false,
            sort: false,
            sql_column: nil,
            th: nil,
            th_append: nil,
            visible: true,
            width: nil,

            show: show,
            edit: edit,
            destroy: destroy
          }
        end

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
