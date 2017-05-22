module Effective
  module EffectiveDatatable
    module Attributes

      private

      def initial_attributes(args)
        raise "#{self.class.name}.new() expected Hash like arguments" unless args.kind_of?(Hash)
        args
      end

      def load_attributes!
        if datatables_ajax_request?
          raise 'Expected attributes cookie to be present' unless cookie[:attributes]
          # Cookie will still be just values here.  Attributes is the first value.

          @attributes = cookie.delete(:attributes)
        end

        unless datatables_ajax_request?
          @attributes[:controller_namespace] ||= view.controller_path.split('/')[0...-1].join('/').presence
        end
      end

    end
  end
end
