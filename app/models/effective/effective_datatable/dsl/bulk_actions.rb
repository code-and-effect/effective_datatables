module Effective
  module EffectiveDatatable
    module Dsl
      module BulkActions

        def bulk_action(*args)
          datatable._bulk_actions.push(content_tag(:li, link_to_bulk_action(*args)))
        end

        def bulk_download(*args)
          datatable._bulk_actions.push(content_tag(:li, link_to_bulk_action(*args), 'data-authenticity-token' => form_authenticity_token))
        end

        def bulk_action_divider
          datatable._bulk_actions.push(content_tag(:li, '', class: 'divider', role: 'separator'))
        end

        def bulk_action_content(&block)
          datatable._bulk_actions.push(block.call)
        end

        private

        # We can't let any data-method be applied to the link, or jquery_ujs does the wrong thing with it
        def link_to_bulk_action(*args)
          args.map! do |arg|
            if arg.kind_of?(Hash)
              data_method = (
                arg.delete(:'data-method') ||
                arg.delete('data-method') ||
                (arg[:data] || {}).delete('method') ||
                (arg[:data] || {}).delete(:method)
              )

              # But if the data-method was :get, we add bulk-actions-get-link = true
              if data_method.to_s == 'get'
                arg[:data].present? ? arg[:data]['bulk-actions-get'] = true : arg['data-bulk-actions-get'] = true
              end
            end

            arg
          end

          link_to(*args)
        end

      end
    end
  end
end
