module Effective
  module EffectiveDatatable
    module Inline

      def inline_payload
        payload = attributes.merge(_datatable_id: to_param)
        EffectiveDatatables.encode_inline_payload(payload)
      end

    end
  end
end
