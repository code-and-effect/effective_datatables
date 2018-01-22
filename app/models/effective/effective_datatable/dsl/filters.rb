module Effective
  module EffectiveDatatable
    module Dsl
      module Filters
        def filter(name = nil, value = :_no_value, as: nil, label: nil, parse: nil, required: false, **input_html)
          return datatable.filter if (name == nil && value == :_no_value) # This lets block methods call 'filter' and get the values

          raise 'expected second argument to be a value' if value == :_no_value
          raise 'parse must be a Proc' if parse.present? && !parse.kind_of?(Proc)

          # Merge search
          if input_html.kind_of?(Hash) && input_html[:search].kind_of?(Hash)
            input_html = input_html.merge(input_html[:search])
          end

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
        def form(url: nil, verb: nil)
          url ||= request.path
          verb ||= (Rails.application.routes.recognize_path(url, method: :post).present? rescue false) ? :post : :get

          datatable._form[:url] = url
          datatable._form[:verb] = verb
        end

        def changes_columns_count
          form()
        end
        alias_method :changes_column_count, :changes_columns_count

      end
    end
  end
end
