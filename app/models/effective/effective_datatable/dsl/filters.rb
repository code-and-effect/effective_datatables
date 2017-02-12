module Effective
  module EffectiveDatatable
    module Dsl
      module Filters
        def filter(name, value, as: nil, label: nil, parse: nil, required: false, **input_html, &block)
          raise 'parse must be a Proc' if parse.present? && !parse.kind_of?(Proc)

          datatable.filters[name.to_sym] = {
            value: value,
            as: as,
            label: label || name.to_s.titleize,
            name: name.to_sym,
            parse: parse,
            required: required,
            input_html: input_html,
            block: (block if block_given?)
          }
        end

        def scope(name, default: nil, label: nil, &block)
          datatable.scopes[name.to_sym] = {
            default: default,
            label: label || name.to_s.titleize,
            block: (block if block_given?)
          }
        end

      end
    end
  end
end
