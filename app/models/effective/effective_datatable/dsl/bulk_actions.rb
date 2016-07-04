module Effective
  module EffectiveDatatable
    module Dsl
      module BulkActions
        # These get added into the view as helpers
        # To be called inside datatable { bulk_actions_column do .. end }
        def bulk_action(*args)
          view.instance_exec { concat content_tag(:li, link_to(*args)) }
        end

        def bulk_action_divider
          view.instance_exec { concat content_tag(:li, '', class: 'divider', role: 'separator') }
        end

        def bulk_action_content(&block)
          view.instance_exec { concat block.call }
        end

      end
    end
  end
end
