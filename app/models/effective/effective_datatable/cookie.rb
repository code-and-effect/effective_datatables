module Effective
  module EffectiveDatatable
    module Cookie
      def cookie
        @cookie
      end

      def cookie_key
        @cookie_key ||= (datatables_ajax_request? ? view.params[:cookie] : cookie_param)
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

      def save_cookie!
        @dt_cookie ||= []
        @dt_cookie << [cookie_key, cookie_payload]

        while @dt_cookie.to_s.size > EffectiveDatatables.max_cookie_size.to_i
          @dt_cookie.shift((@dt_cookie.length / 3) + 1)
        end

        view.cookies.signed['_effective_dt'] = Base64.encode64(Marshal.dump(@dt_cookie))
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
        [attributes.delete_if { |k, v| v.nil? }] + payload.values
      end

    end
  end
end
