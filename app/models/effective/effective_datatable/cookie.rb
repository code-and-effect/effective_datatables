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
        @cookie[cookie_name] = _cookie_to_save

        Rails.logger.info "SAVING COOKIE: #{@cookie}"

        view.cookies.signed['_effective_dt'] = Base64.encode64(Marshal.dump(@cookie))
      end

      def _cookie_to_save
        payload = { attributes: attributes.dup, state: state.dup }

        # Turn visible into a bitmask
        payload[:state][:visible] = columns.keys.map { |name| (2 ** columns[name][:index]) if state[:visible][name] }.compact.sum

        payload
      end

    end
  end
end
