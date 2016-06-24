module Effective
  module EffectiveDatatable
    module Dsl
      module Charts
        # Instance Methods inside the charts do .. end block
        def chart(name, type, options = {}, &block)

          (@charts ||= HashWithIndifferentAccess.new)[name] = {
            name: name,
            type: type,
            partial: options.delete(:partial),
            options: options.reverse_merge(title: name.to_s.titleize),
            block: (block if block_given?)
          }
        end
      end
    end
  end
end
