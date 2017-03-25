module Effective
  module EffectiveDatatable
    module Dsl
      module Filters
        def filter(name = nil, value = :_no_value, as: nil, label: nil, parse: nil, required: false, **input_html)
          return datatable.filter if (name == nil && value == :_no_value) # This lets block methods call 'filter' and get the values

          raise 'expected second argument to be a value' if value == :_no_value
          raise 'parse must be a Proc' if parse.present? && !parse.kind_of?(Proc)

          datatable._filters[name.to_sym] = {
            value: value,
            as: as,
            label: label || name.to_s.titleize,
            name: name.to_sym,
            parse: parse,
            required: required,
            input_html: input_html
          }
        end

        def scope(name = nil, *args, default: nil, label: nil)
          return datatable.scope unless name # This lets block methods call 'scope' and get the values

          datatable._scopes[name.to_sym] = {
            default: default,
            label: label || name.to_s.titleize,
            name: name.to_sym,
            args: args.presence
          }
        end

        # This changes the filters from using an AJAX, to a POST or GET
        def changes_column_count(url: url, verb: nil)
          verb ||= (Rails.application.routes.recognize_path(request.path, method: :post).present? rescue false) ? :post : :get

          datatable._form[:url] = url || request.path
          datatable._form[:verb] = verb
        end
      end
    end
  end
end
