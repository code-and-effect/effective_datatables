module Effective
  module EffectiveDatatable
    module Dsl
      module Charts
        # Instance Methods inside the charts do .. end block
        def chart(name, type, options = {}, &block)

          options[:title] ||= (options[:label] || name.to_s.titleize)
          options[:legend] = 'none' if options[:legend] == false

          (@charts ||= HashWithIndifferentAccess.new)[name] = {
            name: name,
            type: type,
            partial: options.delete(:partial),
            options: options,
            block: (block if block_given?)
          }
        end
      end
    end
  end
end
