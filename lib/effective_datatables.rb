require 'effective_bootstrap'
require 'effective_resources'
require 'effective_datatables/engine'
require 'effective_datatables/version'

module EffectiveDatatables
  mattr_accessor :authorization_method

  mattr_accessor :default_length
  mattr_accessor :html_class
  mattr_accessor :save_state

  mattr_accessor :cookie_max_size
  mattr_accessor :cookie_domain
  mattr_accessor :cookie_tld_length

  mattr_accessor :debug

  alias_method :max_cookie_size, :cookie_max_size
  alias_method :max_cookie_size=, :cookie_max_size=

  def self.setup
    yield self
  end

  def self.authorized?(controller, action, resource)
    @_exceptions ||= [Effective::AccessDenied, (CanCan::AccessDenied if defined?(CanCan)), (Pundit::NotAuthorizedError if defined?(Pundit))].compact

    return !!authorization_method unless authorization_method.respond_to?(:call)
    controller = controller.controller if controller.respond_to?(:controller) # Do the right thing with a view

    begin
      !!(controller || self).instance_exec((controller || self), action, resource, &authorization_method)
    rescue *@_exceptions
      false
    end
  end

  def self.authorize!(controller, action, resource)
    raise Effective::AccessDenied.new('Access Denied', action, resource) unless authorized?(controller, action, resource)
  end

  def self.find(id)
    id = id.to_s.gsub(/-\d+\z/, '').gsub('-', '/')
    klass = (id.classify.safe_constantize || id.classify.pluralize.safe_constantize)

    klass.try(:new) || raise('unable to find datatable')
  end

end
