require 'effective_bootstrap'
require 'effective_resources'
require 'effective_datatables/engine'
require 'effective_datatables/version'

module EffectiveDatatables
  AVAILABLE_LOCALES = %w(en es nl)

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

  def self.find(id, attributes = nil)
    id = id.to_s.gsub(/-\d+\z/, '').gsub('-', '/')
    klass = (id.classify.safe_constantize || id.classify.pluralize.safe_constantize)
    attributes = decode_attributes(attributes)

    klass.try(:new, **attributes) || raise('unable to find datatable')
  end

  # Locale is coming from view. I think it can be dynamic.
  # We currently support: en, es, nl
  def self.language(locale)
    @_languages ||= {}

    locale = :en unless AVAILABLE_LOCALES.include?(locale.to_s)

    @_languages[locale] ||= begin
      path = Gem::Specification.find_by_name('effective_datatables').gem_dir + "/app/assets/javascripts/dataTables/locales/#{locale}.lang"
      JSON.parse(File.read(path)).to_json
    end
  end

  def self.encode_attributes(attributes)
    payload = Base64.encode64(Marshal.dump(attributes))
  end

  def self.decode_attributes(payload)
    return payload if payload.kind_of?(Hash)

    attributes = Marshal.load(Base64.decode64(payload))
    raise 'invalid decoded inline payload' unless attributes.kind_of?(Hash)

    attributes
  end

end
