require_relative '../../app/helpers/effective_datatables_controller_helper'
require_relative '../../app/helpers/effective_datatables_helper'
require_relative '../../app/helpers/effective_datatables_private_helper'

module EffectiveDatatables
  class Engine < ::Rails::Engine
    engine_name 'effective_datatables'

    config.autoload_paths += Dir["#{config.root}/app/models/concerns", '/app/datatables/**/']

    initializer 'effective_datatables.assets' do |app|
      app.config.assets.precompile += ['effective_datatables_manifest.js', 'images/*']
    end

    # Include Helpers to base application
    initializer 'effective_datatables.action_controller' do |app|
      app.config.to_prepare do
        ActiveSupport.on_load :action_controller_base do
          helper EffectiveDatatablesHelper
          helper EffectiveDatatablesPrivateHelper

          ActionController::Base.send :include, ::EffectiveDatatablesControllerHelper
        end
      end
    end

    # Set up our default configuration options.
    initializer 'effective_datatables.defaults', before: :load_config_initializers do |app|
      eval File.read("#{config.root}/config/effective_datatables.rb")
    end
  end
end
