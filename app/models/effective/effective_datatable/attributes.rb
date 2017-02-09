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
          attributes = Marshal.load(view.cookies.signed[attributes_cookie_name])
          raise 'invalid attributes cookie' unless attributes.kind_of?(Hash)
          @attributes = attributes
        else
          save_attributes!
        end
      end

      def save_attributes!
        view.cookies.signed[attributes_cookie_name] = Marshal.dump(attributes)
      end

      def attributes_cookie_name
        @attributes_cookie_name ||= (
          Base64.encode64(['attributes', to_param, URI(view.request.referer || view.request.url).path].join)
        )
      end

    end
  end
end
