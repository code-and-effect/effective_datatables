module Effective
  module EffectiveDatatable
    module Attributes

      private

      def initial_attributes(args)
        raise "#{self.class.name}.new() expected Hash like arguments" unless args.kind_of?(Hash)
        args
      end

      def load_attributes!
        if datatables_ajax_request? || datatables_inline_request?
          @attributes = cookie.delete(:attributes)
        else
          @attributes[:_n] ||= view.controller_path.split('/')[0...-1].join('/').presence
        end
      end

    end
  end
end
