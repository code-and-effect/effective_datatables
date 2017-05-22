module Effective
  module EffectiveDatatable
    module Cookie
      MAX_COOKIE_SIZE = 2500  # String size. Real byte size is about 1.5 times bigger.

      def cookie
        @cookie
      end

      def cookie_name
        @cookie_name ||= (
          if datatables_ajax_request?
            view.params[:cookie]
          else
            [self.class, attributes].hash.to_s.last(12)
          end
        )
      end

      private

      def load_cookie!
        @dt_cookie = view.cookies.signed['_effective_dt']

        # Load global datatables cookie
        if @dt_cookie.present?
          @dt_cookie = Marshal.load(Base64.decode64(@dt_cookie))
          raise 'invalid datatables cookie' unless @dt_cookie.kind_of?(Array)

          # Assign individual cookie
          index = @dt_cookie.rindex { |name, _| name == cookie_name }
          @cookie = @dt_cookie.delete_at(index) if index
        end

        # Load my individual cookie
        if @cookie.kind_of?(Array)
          @cookie = initial_state.keys.zip(@cookie.second).to_h
        end
      end

      def save_cookie!
        @dt_cookie ||= []
        @dt_cookie << [cookie_name, cookie_payload]

        while @dt_cookie.to_s.size > MAX_COOKIE_SIZE
          @dt_cookie.shift((@dt_cookie.length / 3) + 1)
        end

        view.cookies.signed['_effective_dt'] = Base64.encode64(Marshal.dump(@dt_cookie))
      end

      def cookie_payload
        payload = state.except(:attributes)

        # Turn visible into a bitmask.  This is undone in load_columns!
        payload[:visible] = (
          if columns.keys.length < 63 # 64-bit integer
            columns.keys.map { |name| (2 ** columns[name][:index]) if state[:visible][name] }.compact.sum
          end
        )

        # Just store the values
        [attributes.delete_if { |k, v| v.nil? }] + payload.values
      end

    end
  end
end
