module Effective
  module EffectiveDatatable
    module Cookie

      attr_reader :cookie

      def load_cookie!
        @cookie ||= (
          cookie = view.cookies.signed[cookie_name]

          if cookie.present?
            data = Marshal.load(Base64.decode64(cookie))
            raise 'invalid cookie' unless [data, data[:attributes], data[:state]].all? { |obj| obj.kind_of?(Hash) }
            data
          end
        )
      end

      def save_cookie!
        view.cookies.signed[cookie_name] = Base64.encode64(Marshal.dump(attributes: attributes, state: state))
      end

      def cookie_name
        @cookie_name ||= "datatable-#{URI(datatables_ajax_request? ? view.request.referer : view.request.url).path}-#{to_param}".parameterize
      end

    end
  end
end
