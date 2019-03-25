module Effective
  module EffectiveDatatable
    module Cookie

      def cookie
        @cookie
      end

      def cookie_key
        @cookie_key ||= (
          if datatables_ajax_request?
            view.params[:cookie]
          elsif datatables_inline_request?
            view.params[:_datatable_cookie]
          else
            cookie_param
          end
        )
      end

      # All possible dt cookie keys.  Used to make sure the datatable has a cookie set for this session.
      def cookie_keys
        @cookie_keys ||= Array(@dt_cookie).compact.map(&:first)
      end

      def cookie_param
        [self.class, attributes].hash.abs.to_s.last(12) # Not guaranteed to be 12 long
      end

      private

      def load_cookie!
        @dt_cookie = view.cookies.signed['_effective_dt']

        # Load global datatables cookie
        if @dt_cookie.present?
          @dt_cookie = Marshal.load(Base64.decode64(@dt_cookie))
          raise 'invalid datatables cookie' unless @dt_cookie.kind_of?(Array)

          # Assign individual cookie
          index = @dt_cookie.rindex { |key, _| key == cookie_key }
          @cookie = @dt_cookie.delete_at(index) if index
        end

        # Load my individual cookie
        if @cookie.kind_of?(Array)
          @cookie = initial_state.keys.zip(@cookie.second).to_h
        end
      end

      def assert_cookie!
        if datatables_ajax_request? || datatables_inline_request?
          raise 'expected cookie to be present' unless cookie
          raise 'expected attributes cookie to be present' unless cookie[:attributes]
        end
      end

      def save_cookie!
        @dt_cookie ||= []
        @dt_cookie << [cookie_key, cookie_payload]

        while @dt_cookie.to_s.size > EffectiveDatatables.cookie_max_size.to_i
          @dt_cookie.shift((@dt_cookie.length / 3) + 1)
        end

        # Generate cookie
        domain = EffectiveDatatables.cookie_domain || :all
        tld_length = EffectiveDatatables.cookie_tld_length
        tld_length ||= (view.request.host == 'localhost' ? nil : view.request.host.to_s.split('.').count)

        view.cookies.signed['_effective_dt'] = { value: Base64.encode64(Marshal.dump(@dt_cookie)), domain: domain, tld_length: tld_length }.compact
      end

      def cookie_payload
        payload = state.except(:attributes, :visible)

        # Turn visible into a bitmask.  This is undone in load_columns!
        payload[:vismask] = (
          if columns.keys.length < 63 # 64-bit integer
            columns.keys.map { |name| (2 ** columns[name][:index]) if state[:visible][name] }.compact.sum
          end
        )

        # Just store the values
        [attributes] + payload.values
      end

    end
  end
end
