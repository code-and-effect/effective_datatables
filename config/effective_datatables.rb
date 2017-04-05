EffectiveDatatables.setup do |config|
  # Authorization Method
  #
  # This method is called by all controller actions with the appropriate action and resource
  # If the method returns false, an Effective::AccessDenied Error will be raised (see README.md for complete info)
  #
  # Use via Proc (and with CanCan):
  # config.authorization_method = Proc.new { |controller, action, resource| authorize!(action, resource) }
  #
  # Use via custom method:
  # config.authorization_method = :my_authorization_method
  #
  # And then in your application_controller.rb:
  #
  # def my_authorization_method(action, resource)
  #   current_user.is?(:admin)
  # end
  #
  # Or disable the check completely:
  # config.authorization_method = false
  config.authorization_method = Proc.new { |controller, action, resource| authorize!(action, resource) } # CanCanCan

  # Default number of entries shown per page
  # Valid options are: 5, 10, 25, 50, 100, 250, 1000, :all
  config.default_length = 25

  # When using the actions_column DSL method, apply the following behavior
  # Valid values for each action are:
  # true - display this action if authorized?(:show, Post)
  # false - do not display this action
  # :authorize - display this action if authorized?(:show, Post<3>)  (every instance is checked)
  #
  # You can override these defaults on a per-table basis
  # by calling `actions_column(show: false, edit: true, destroy: :authorize)`
  config.actions_column = {
    show: true,
    edit: true,
    destroy: true,
  }

  # Which packages to load when using the charts DSL
  config.google_chart_packages = ['corechart']

end
