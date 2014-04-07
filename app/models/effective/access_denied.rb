unless defined?(Effective::AccessDenied)
  module Effective
    class AccessDenied < StandardError
      attr_reader :action, :subject

      def initialize(message = nil, action = nil, subject = nil)
        @message = message
        @action = action
        @subject = subject
      end

      def to_s
        @message || I18n.t(:'unauthorized.default', :default => 'Access Denied')
      end
    end
  end
end
