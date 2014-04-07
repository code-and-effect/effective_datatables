module EffectiveDatatables
  module Generators
    class InstallGenerator < Rails::Generators::Base
      desc "Creates an EffectiveDatatables initializer in your application."

      source_root File.expand_path("../../templates", __FILE__)

      def copy_initializer
        template "effective_datatables.rb", "config/initializers/effective_datatables.rb"
      end

      def setup_routes
        inject_into_file "config/routes.rb", "\n  mount EffectiveDatatables::Engine => '/', :as => 'effective_datatables'", :after => /root (:?)to.*/
      end

      def show_readme
        readme "README" if behavior == :invoke
      end
    end
  end
end
