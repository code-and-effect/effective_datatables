module Effective
  module EffectiveDatatable
    module Dsl
      module BulkActions

        def bulk_action(*args)
          datatable.bulk_actions.push(content_tag(:li, link_to(*args)))
        end

        def bulk_download(*args)
          datatable.bulk_actions.push(content_tag(:li, link_to(*args), 'data-authenticity-token' => form_authenticity_token))
        end

        def bulk_action_divider
          datatable.bulk_actions.push(content_tag(:li, '', class: 'divider', role: 'separator'))
        end

        def bulk_action_content(&block)
          datatable.bulk_actions.push(block.call)
        end

      end
    end
  end
end
