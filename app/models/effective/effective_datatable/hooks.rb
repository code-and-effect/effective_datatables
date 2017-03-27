module Effective
  module EffectiveDatatable
    module Hooks

      # Called on the final collection after searching, ordering, arrayizing and formatting have been completed
      def finalize(collection) # Override me if you like
        collection
      end

    end
  end
end
