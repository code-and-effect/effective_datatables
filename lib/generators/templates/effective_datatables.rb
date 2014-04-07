EffectiveDatatables.setup do |config|
  # Authorization Method
  config.authorization_method = Proc.new { |controller, action, resource| can?(action, resource) || true } # CanCan gem
end
