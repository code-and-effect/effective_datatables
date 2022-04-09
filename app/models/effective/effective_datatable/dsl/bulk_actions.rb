# frozen_string_literal: true

module Effective
  module EffectiveDatatable
    module Dsl
      module BulkActions

        def bulk_action(title, url, opts = {})
          datatable._bulk_actions.push(link_to_bulk_action(title, url, opts))
        end

        def bulk_download(title, url, opts = {})
          datatable._bulk_actions.push(link_to_bulk_action(title, url, opts.merge('data-bulk-download': true)))
        end

        def bulk_action_divider
          datatable._bulk_actions.push(content_tag(:div, '', class: 'dropdown-divider'))
        end

        def bulk_action_content(&block)
          datatable._bulk_actions.push(block.call)
        end

        private

        # We can't let any data-method be applied to the link, or jquery_ujs does the wrong thing with it
        def link_to_bulk_action(title, url, opts = {})

          # Transform data: { ... } hash into 'data-' keys
          if (data = opts.delete(:data))
            data.each { |k, v| opts["data-#{k}"] ||= v }
          end

          verbs = {'DELETE' => 'DELETE', 'GET' => 'GET'}
          opts['data-ajax-method'] = verbs[opts.delete('data-method').to_s.upcase] || 'POST'

          opts[:class] = [opts[:class], 'dropdown-item'].compact.join(' ')

          link_to(title, url, **opts)
        end

      end
    end
  end
end
