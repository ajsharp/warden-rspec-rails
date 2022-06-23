# frozen_string_literal: true

require "warden" # just in case

# Based on http://stackoverflow.com/questions/13420923/configuring-warden-for-use-in-rspec-controller-specs
module Warden
  # Warden::Test::ControllerHelpers provides a facility to test controllers in isolation
  # Most of the code was extracted from Devise's Devise::Test::ControllerHelpers.
  module Test
    module ControllerHelpers
      extend ActiveSupport::Concern

      included do
        setup :setup_controller_for_warden, :warden # if respond_to?(:setup)
      end

      # Override process to consider warden.
      def process(*, **)
        _catch_warden { super }

        @response
      end

      # We need to setup the environment variables and the response in the controller
      def setup_controller_for_warden
        @request.env['action_controller.instance'] = @controller
      end

      # Quick access to Warden::Proxy.
      def warden #:nodoc:
        @request.env['warden'] ||= begin
          manager = Warden::Manager.new(nil, &Rails.application.config.middleware.detect { |m| m.name.include?('Warden::Manager') }.block)
          Warden::Proxy.new(@request.env, manager)
        end
      end

      # Warden::Test::Helpers style login_as for controller tests.
      def login_as(user, opts = {})
        opts[:event] ||= :authentication
        warden.set_user(user, opts)
      end

      # Warden::Test::Helpers style logout for controller tests.
      def logout(*scopes)
        warden.logout(*scopes)
      end

      # Reset the logins without logging out, so the next request will fetch.
      def unlogin(*scopes)
        users = warden.instance_variable_get(:@users)
        if scopes.empty?
          users.clear
        else
          scopes.each { |scope| users.delete(scope) }
        end
      end

      protected

      # Catch warden continuations and handle like the middleware would.
      # Returns nil when interrupted, otherwise the normal result of the block.
      def _catch_warden(&block)
        result = catch(:warden, &block)

        env = @controller.request.env

        result ||= {}

        # Set the response. In production, the rack result is returned
        # from Warden::Manager#call, which the following is modelled on.
        case result
        when Array
          if result.first == 401 && intercept_401?(env) # does this happen during testing?
            _process_unauthenticated(env)
          else
            result
          end
        when Hash
          _process_unauthenticated(env, result)
        else
          result
        end
      end

      def _process_unauthenticated(env, options = {})
        proxy = request.env['warden']
        options[:action] ||= begin
          opts = proxy.config[:scope_defaults][proxy.config.default_scope] || {}
          opts[:action] || "unauthenticated"
        end
        result = options[:result] || proxy.result

        ret = case result
        when :redirect
          body = proxy.message || "You are being redirected to #{proxy.headers['Location']}"
          [proxy.status, proxy.headers, [body]]
        when :custom
          proxy.custom_response
        else
          request.env["PATH_INFO"] = "/#{options[:action]}"
          request.env["warden.options"] = options
          Warden::Manager._run_callbacks(:before_failure, env, options)

          status, headers, response = warden.config[:failure_app].call(env).to_a
          @controller.response.headers.merge!(headers)
          @controller.status = status
          @controller.response.body = response.body
          nil # causes process return @response
        end

        # ensure that the controller response is set up. In production, this is
        # not necessary since warden returns the results to rack. However, at
        # testing time, we want the response to be available to the testing
        # framework to verify what would be returned to rack.
        if ret.is_a?(Array)
          status, headers, body = *ret
          # ensure the controller response is set to our response.
          @controller.response ||= @response
          @response.status = status
          @response.headers.merge!(headers)
          @response.body = body
        end

        ret
      end
    end
  end
end
