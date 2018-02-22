module EffectiveDatatables
  class Engine < ::Rails::Engine
    engine_name 'effective_datatables'

    config.autoload_paths += Dir["#{config.root}/app/models/concerns", '/app/datatables/**/', "#{config.root}/lib/effective_style_guide/"]

    # Include Helpers to base application
    initializer 'effective_datatables.action_controller' do |app|
      ActiveSupport.on_load :action_controller do
        helper EffectiveDatatablesHelper
        helper EffectiveDatatablesPrivateHelper

        ActionController::Base.send :include, ::EffectiveDatatablesControllerHelper
      end
    end

    # Set up our default configuration options.
    initializer 'effective_datatables.defaults', before: :load_config_initializers do |app|
      eval File.read("#{config.root}/config/effective_datatables.rb")
    end
  end
end
