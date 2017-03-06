module Effective
  module EffectiveDatatable
    module Dsl
      module Filters
        def filter(name = nil, value = :_no_value, as: nil, label: nil, parse: nil, required: false, **input_html)
          return datatable.state[:filter] unless (name || value) # This lets block methods call 'filter' and get the values

          raise 'expected second argument to be a value' if value == :_no_value
          raise 'parse must be a Proc' if parse.present? && !parse.kind_of?(Proc)

          datatable.filters[name.to_sym] = {
            value: value,
            as: as,
            label: label || name.to_s.titleize,
            name: name.to_sym,
            parse: parse,
            required: required,
            input_html: input_html
          }
        end

        def scope(name = nil, default: nil, label: nil)
          return datatable.state[:scope] unless name # This lets block methods call 'scope' and get the values

          datatable.scopes[name.to_sym] = {
            default: default,
            label: label || name.to_s.titleize,
          }
        end

      end
    end
  end
end
