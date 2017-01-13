module Effective
  module EffectiveDatatable
    module Dsl
      module Scopes
        # Instance Methods inside the scopes do .. end block
        def scope(name, default = nil, options = {}, &block)
          if block_given?
            raise "You cannot use partial: ... with the block syntax" if options[:partial]
            options[:block] = block
          end

          # This needs to be a {} not WithIndifferentAccess or rendering _scopes won't work correctly
          (@scopes ||= {})[name] = options.merge(default: default)
        end
      end
    end
  end
end
