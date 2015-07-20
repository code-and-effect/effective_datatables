# This is extended as class level into Datatable

module Effective
  module Datatables
    module Dsl
      def all
        EffectiveDatatables.datatables.map { |klass| klass.new() }
      end

      def find(obj, attributes = nil)
        obj = obj.respond_to?(:to_param) ? obj.to_param : obj
        EffectiveDatatables.datatables.find { |klass| klass.name.underscore.parameterize == obj }.try(:new, attributes.presence || {})
      end

      def table_column(name, options = {}, proc = nil, &block)
        if block_given?
          raise "You cannot use :partial => '' with the block syntax" if options[:partial]
          raise "You cannot use :proc => ... with the block syntax" if options[:proc]
          options[:block] = block
        end
        raise "You cannot use both :partial => '' and proc => ..." if options[:partial] && options[:proc]

        send(:attr_accessor, name)
        (@table_columns ||= HashWithIndifferentAccess.new())[name] = options
      end

      def table_columns(*names)
        names.each { |name| table_column(name) }
      end

      def dynamic_columns(&block)
        define_method(:dynamic_columns) { self.instance_exec(&block) }
      end

      def array_column(name, options = {}, proc = nil, &block)
        table_column(name, options.merge!({:array_column => true}), proc, &block)
      end

      def actions_column(options = {}, proc = nil, &block)
        show = options.fetch(:show, false)
        edit = options.fetch(:edit, true)
        destroy = options.fetch(:destroy, true)
        name = options.fetch(:name, 'actions')

        opts = {
          sortable: false,
          filter: false,
          partial_local: :resource,
          partial_locals: { show_action: show, edit_action: edit, destroy_action: destroy }
        }
        opts[:partial] = '/effective/datatables/actions_column' unless (block_given? || proc.present?)

        table_column(name, opts, proc, &block)
      end

      def array_columns(*names)
        names.each { |name| array_column(name) }
      end

      def default_order(name, direction = :asc)
        @default_order = {name => direction}
      end

      def default_entries(entries)
        @default_entries = entries
      end

      def model_name # Searching & Filters
        @model_name ||= ActiveModel::Name.new(self)
      end
    end
  end
end
