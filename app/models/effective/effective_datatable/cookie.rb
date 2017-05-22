module Effective
  module EffectiveDatatable
    module Cookie

      def cookie
        (@cookie ||= {})[cookie_name]
      end

      def cookie_name
        @cookie_name ||= "#{URI(datatables_ajax_request? ? view.request.referer : view.request.url).path}-#{to_param}".parameterize
      end

      private

      def load_cookie!
        @cookie = view.cookies.signed['_effective_dt']

        if @cookie.present?
          @cookie = Marshal.load(Base64.decode64(@cookie))
          raise 'invalid cookie' unless @cookie.kind_of?(Hash)

          if @cookie[cookie_name].present?
            @cookie[cookie_name] = initial_state.keys.zip(@cookie[cookie_name]).to_h
          end
        end

        Rails.logger.info "LOADED COOKIE: #{@cookie}"
      end

      def save_cookie!
        @cookie ||= {}
        @cookie[cookie_name] = _cookie_to_save

        Rails.logger.info "SAVING COOKIE (#{@cookie.keys.length} TABLES): #{@cookie}"

        view.cookies.signed['_effective_dt'] = Base64.encode64(Marshal.dump(@cookie))
      end

      def _cookie_to_save
        payload = state.except(:attributes)

        # Turn visible into a bitmask.  This is undone in load_columns!
        payload[:visible] = (
          if columns.keys.length < 63 # 64-bit integer
            columns.keys.map { |name| (2 ** columns[name][:index]) if state[:visible][name] }.compact.sum
          end
        )

        # Just store the values
        payload = [attributes.delete_if { |k, v| v.nil? }] + payload.values

        payload
      end

    end
  end
end
