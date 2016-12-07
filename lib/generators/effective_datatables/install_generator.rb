module EffectiveDatatables
  module Generators
    class InstallGenerator < Rails::Generators::Base
      desc "Creates an EffectiveDatatables initializer in your application."

      source_root File.expand_path("../../templates", __FILE__)

      def copy_initializer
        template 'effective_datatables.rb', 'config/initializers/effective_datatables.rb'
      end

    end
  end
end
