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

  # Log search/sort information to the console
  config.debug = true

  # Use a cookie to save and restore state from previous page visits.
  config.save_state = true

  # Configure the _effective_dt cookie.
  config.cookie_max_size = 1500       # String size. Final byte size is about 1.5 times bigger, after rails signs it
  config.cookie_domain = :all         # Should usually be :all
  config.cookie_tld_length = nil      # Leave nil to autodetect, or set to probably 2

end
