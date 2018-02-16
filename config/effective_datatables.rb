EffectiveDatatables.setup do |config|
  # Authorization Method
  #
  # This method is called by all controller actions with the appropriate action and resource
  # If it raises an exception or returns false, an Effective::AccessDenied Error will be raised
  #
  # Use via Proc:
  # Proc.new { |controller, action, resource| authorize!(action, resource) }       # CanCan
  # Proc.new { |controller, action, resource| can?(action, resource) }             # CanCan with skip_authorization_check
  # Proc.new { |controller, action, resource| authorize "#{action}?", resource }   # Pundit
  # Proc.new { |controller, action, resource| current_user.is?(:admin) }           # Custom logic
  #
  # Use via Boolean:
  # config.authorization_method = true  # Always authorized
  # config.authorization_method = false # Always unauthorized
  #
  # Use via Method (probably in your application_controller.rb):
  # config.authorization_method = :my_authorization_method
  # def my_authorization_method(resource, action)
  #   true
  # end
  config.authorization_method = Proc.new { |controller, action, resource| authorize!(action, resource) }

  # Default number of entries shown per page
  # Valid options are: 5, 10, 25, 50, 100, 250, 500, :all
  config.default_length = 25

  # Default class used on the <table> tag
  config.html_class = 'table table-hover'

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

  # Log search/sort information to the console
  config.debug = true

end
