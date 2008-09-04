# Camper: simplifies camping deployment
# http://www.google.com/group/object_id
#

require 'rubygems'
require 'camping'
require 'camping/session'
require 'camping/ar'
require 'camping/ar/session'
require 'camper/camper_page_caching'
require 'camper/camper_helpers'
require 'ftools'

# A Rack middleware for reading X-Sendfile. Should only be used in development. -from camping/server
class XSendfile

    HEADERS = [
        "X-Sendfile",
        "X-Accel-Redirect",
        "X-LIGHTTPD-send-file"
    ]

    def initialize(app)
        @app = app
    end

    def call(env)
        status, headers, body = @app.call(env)
        if path = headers.values_at(*HEADERS).compact.first
            body = File.read(path)
        end
        [status, headers, body]
    end
end

module Camping
    VALID_KEYS = %w[app app_name port root adapter database user password logger timestamp]
    class << self
        #class instance var accessors
        attr_reader *VALID_KEYS
        alias_method :_old_goes_, :goes

        def init

            @app.module_eval do
                Mab.set(:indent, 1) #debug html
            end

            @app::Views.module_eval do
                # Here's a little technique you can use to support multiple layouts within a Camping app.
                def layout
                    @current_layout ||= :default_layout
                    send("#{@current_layout}"){ yield }
                end
            end

            @app::Helpers.module_eval do
                include PageCaching
                include CampingHelpers
            end
        end

        def goes(symbol)
            # this is your camping app
            Camping._old_goes_ symbol

            @app_name  = symbol.to_s.underscore
            @app       = symbol.to_s.constantize
            @timestamp = Time.now.strftime("%Y%m%d")
            init
        end

        def start(opts={})

            opts[:port]     ||= 3301
            opts[:root]     ||= nil   #|| 'http://localhost' #causes error if run
            opts[:adapter]  ||= 'sqlite3'
            opts[:user]     ||= 'root'
            opts[:password] ||= ''
            opts[:logger]   ||= nil
            opts[:database] ||= /sqlite/.match(opts[:adapter]) ? File.expand_path("#{app_name}.sqlite3") : app_name

            instance_eval do
                opts.each do |k, v|
                    instance_variable_set("@#{k}", v)
                end
            end

            logfile = [Camping.app, Camping.timestamp, "log"].join(".")
            pidfile = [Camping.app, "pid"].join(".")

            # database connection configuration

            app::Models::Base.establish_connection opts

            #        require 'ar-extensions'   #comment me out if you need this activerecord extension

            if logger
                app::Models::Base.colorize_logging = false
                app::Models::Base.logger           = Logger.new(logfile) # comment me out if you don't want to log
            end

            app::Models::Base.allow_concurrency = true
            app.create

            # run the web server
            runapp = Rack::Builder.new do
                use Rack::Static, :urls => %w[/static /stylesheets /javascipts]
                use Rack::CommonLogger
                use Rack::ShowExceptions
                use XSendfile
                run Camping.app
            end

            puts "%s camped at localhost %s" % [app, port]
            Rack::Handler::Mongrel.run runapp, :Port => Camping.port, :Root=> Camping.root
        rescue
            p [$!, opts]
        end
    end
end
