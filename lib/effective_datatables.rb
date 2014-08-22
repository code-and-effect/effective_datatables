require "effective_datatables/engine"
require "effective_datatables/version"

module EffectiveDatatables
  mattr_accessor :authorization_method

  def self.setup
    yield self
  end

  def self.authorized?(controller, action, resource)
    raise Effective::AccessDenied.new() unless (controller || self).instance_exec(controller, action, resource, &EffectiveDatatables.authorization_method)
    true
  end

  def self.datatables
    Rails.env.development? ? read_datatables : (@@datatables ||= read_datatables)
  end

  private

  def self.read_datatables
    Rails.application.eager_load! unless Rails.configuration.cache_classes
    Effective::Datatable.descendants.map { |klass| klass }.compact
  end

end
