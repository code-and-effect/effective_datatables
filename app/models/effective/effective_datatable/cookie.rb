module Effective
  module EffectiveDatatable
    module Cookie

      def cookie_name
        @cookie_name ||= "datatable-#{URI(datatables_ajax_request? ? view.request.referer : view.request.url).path}-#{to_param}".parameterize
      end

      private

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
        todelete = view.cookies.map { |name, value| name if (name.start_with?('datatable-') && name != cookie_name) }.compact
        todelete.each { |name| view.cookies.delete(name) }

        view.cookies.signed[cookie_name] = Base64.encode64(Marshal.dump(attributes: attributes, state: state))
      end

    end
  end
end
