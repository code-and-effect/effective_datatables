module Effective
  module EffectiveDatatable
    module Dsl
      module BulkActions

        def bulk_action(*args)
          datatable._bulk_actions.push(content_tag(:li, link_to(*args)))
        end

        def bulk_download(*args)
          datatable._bulk_actions.push(content_tag(:li, link_to(*args), 'data-authenticity-token' => form_authenticity_token))
        end

        def bulk_action_divider
          datatable._bulk_actions.push(content_tag(:li, '', class: 'divider', role: 'separator'))
        end

        def bulk_action_content(&block)
          datatable._bulk_actions.push(block.call)
        end

      end
    end
  end
end
