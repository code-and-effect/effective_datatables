module Effective
  module EffectiveDatatable
    module Cookie


      def cookie_name
        @cookie_name ||= "#{to_param}-#{URI(view.request.referer || view.request.url).path}".parameterize
      end

    end
  end
end
