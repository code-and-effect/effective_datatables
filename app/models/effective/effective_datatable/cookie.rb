module Effective
  module EffectiveDatatable
    module Cookie

      def cookie
        @cookie
      end

      def cookie_name
        @cookie_name ||= "#{URI(datatables_ajax_request? ? view.request.referer : view.request.url).path}-#{to_param}".parameterize
      end

      private

      def load_cookie!
        @dt_cookie = view.cookies.signed['_effective_dt']

        if @dt_cookie.present?
          @dt_cookie = Marshal.load(Base64.decode64(@dt_cookie))
          raise 'invalid datatables cookie' unless @dt_cookie.kind_of?(Array)

          if (index = @dt_cookie.rindex { |name, _| name == cookie_name })
            @cookie = @dt_cookie.delete_at(index)
            @cookie = initial_state.keys.zip(@cookie.second).to_h if @cookie.kind_of?(Array)
          end
        end

        Rails.logger.info "LOADED COOKIE: #{@cookie}"
      end

      def save_cookie!
        @dt_cookie ||= []
        @dt_cookie << [cookie_name, _cookie_to_save]

        Rails.logger.info "SAVING COOKIE (#{@dt_cookie.length} TABLES): #{@dt_cookie}"

        view.cookies.signed['_effective_dt'] = Base64.encode64(Marshal.dump(@dt_cookie))
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
