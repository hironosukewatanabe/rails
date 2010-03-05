require "rails"
require "action_controller"
require "action_view/railtie"
require "active_support/core_ext/class/subclasses"
require "active_support/deprecation/proxy_wrappers"
require "active_support/deprecation"

module ActionController
  class Railtie < Rails::Railtie
    railtie_name :action_controller

    require "action_controller/railties/log_subscriber"
    require "action_controller/railties/url_helpers"

    ad = config.action_dispatch
    config.action_controller.singleton_class.send(:define_method, :session) do
      ActiveSupport::Deprecation.warn "config.action_controller.session has been " \
        "renamed to config.action_dispatch.session.", caller
      ad.session
    end

    config.action_controller.singleton_class.send(:define_method, :session=) do |val|
      ActiveSupport::Deprecation.warn "config.action_controller.session has been " \
        "renamed to config.action_dispatch.session.", caller
      ad.session = val
    end

    config.action_controller.singleton_class.send(:define_method, :session_store) do
      ActiveSupport::Deprecation.warn "config.action_controller.session_store has been " \
        "renamed to config.action_dispatch.session_store.", caller
      ad.session_store
    end

    config.action_controller.singleton_class.send(:define_method, :session_store=) do |val|
      ActiveSupport::Deprecation.warn "config.action_controller.session_store has been " \
        "renamed to config.action_dispatch.session_store.", caller
      ad.session_store = val
    end

    log_subscriber ActionController::Railties::LogSubscriber.new

    initializer "action_controller.logger" do
      ActionController::Base.logger ||= Rails.logger
    end

    initializer "action_controller.set_configs" do |app|
      paths = app.config.paths
      ac = app.config.action_controller
      ac.assets_dir = paths.public.to_a.first
      ac.javascripts_dir = paths.public.javascripts.to_a.first
      ac.stylesheets_dir = paths.public.stylesheets.to_a.first
      ac.secret = app.config.cookie_secret

      if ac.relative_url_root
        ActiveSupport::Deprecation.warn "config.action_controller.relative_url_root " \
          "is no longer effective. Please set it in the router as " \
          "routes.draw(:script_name => #{ac.relative_url_root.inspect})"
      end

      ActionController::Base.config.replace(ac)
    end

    initializer "action_controller.initialize_framework_caches" do
      ActionController::Base.cache_store ||= RAILS_CACHE
    end

    initializer "action_controller.set_helpers_path" do |app|
      ActionController::Base.helpers_path = app.config.paths.app.helpers.to_a
    end

    initializer "action_controller.url_helpers" do |app|
      ActionController::Base.extend ::ActionController::Railtie::UrlHelpers.with(app.routes)

      message = "ActionController::Routing::Routes is deprecated. " \
                "Instead, use Rails.application.routes"

      proxy = ActiveSupport::Deprecation::DeprecatedObjectProxy.new(app.routes, message)
      ActionController::Routing::Routes = proxy
    end
  end
end