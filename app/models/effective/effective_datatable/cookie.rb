module Effective
  module EffectiveDatatable
    module Cookie

      def cookie
        (@cookie ||= {})[cookie_name]
      end

      def cookie_name
        @cookie_name ||= "datatable-#{URI(datatables_ajax_request? ? view.request.referer : view.request.url).path}-#{to_param}".parameterize
      end

      private

      def load_cookie!
        @cookie = view.cookies.signed['_effective_dt']

        if @cookie.present?
          @cookie = Marshal.load(Base64.decode64(@cookie))
          raise 'invalid cookie' unless @cookie.kind_of?(Hash)
        end

        Rails.logger.info "LOADED COOKIE: #{@cookie}"

      end

      def save_cookie!
        @cookie ||= {}
        @cookie[cookie_name] = { attributes: attributes, state: state }

        Rails.logger.info "SAVING COOKIE: #{@cookie}"

        view.cookies.signed['_effective_dt'] = Base64.encode64(Marshal.dump(@cookie))
      end

    end
  end
end
