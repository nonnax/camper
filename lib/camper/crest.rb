# ==Camping REST == CREST
# Yet another RESTful support for Camping Apps
#

class Object #:nodoc:
    def meta_def(m,&b) #:nodoc:
        (class<<self;self end).send(:define_method,m,&b)
    end
end
module CRestful
    def self.included(base) # +nodoc+
        base::Controllers.send :extend,  CRestful::ClassMethods
        base::Mab.send         :include, CRestful::MarkabyHelpers
    end
    # service override for cRESTful action :-)
    def service(*a)
         @method=@request.request_method
         if @method == 'post' && (%w[put delete].include?(input._method.to_s.downcase))
           @env['REQUEST_METHOD'] = input._method.upcase
           @method = input._method
         elsif @method == 'get'
           id, action = a
           gmethod, a=case id
                      when nil        then ['list', []]
                      when 'new', '0' then ['new',  []]
                      else                 ['read', [a.first, action]]
                      end
         end
         super(*a)
         gmethod && (@body=send(gmethod, *a)) 
         self
    end

    class CRestClass
        # == Rest methods
        #  preloads GET and POST methods
        #  override get and post methods with care
        #
        #  GET acts as message dispatcher and maps
        #  GET requests to restful actions READ, LIST and pseudo-rest method NEW
        # * arguments +id+ and +action+ must be provided or simply get(*a), calls the method +action+ (if implemented).
        def get(*a)
            # delegates call to another method
        end
        # POST '/posts'
        def post(*a)
            # creates a record if a==[] else delegates call to another rest method PUT or DELETE
        end
#        # PUT '/posts/1'
#        def put(id)
#        end
#        # DELETE '/posts/1'
#        def delete(id)
#        end
#        # GET '/posts'
#        def list
#        end
#        # GET '/posts/1'
#        def read(id, action)
#        end
#        # pseudo-rest methods
#        # GET '/posts/new'
#        # GET '/posts/0' plays well with AR since find with id==0 is not allowed
#        def new
#        end

    end
    module ClassMethods
         # * Turn a controller into a Restful Resouce.
         #
         #     module Camping::Controllers
         #        class Users < RR '/posts', '/posts/(\d+)', '/posts/(\w+)', '/posts/(\d+)/(\w+)'
         #         # you need to define the following methods:
         #         def new;end
         #         def read(id, action);end
         #         def list;end
         #         def post(id=nil);end
         #         def put(id);end
         #         def delete(id);end
         #        end
         #     end
         #
         # * RestfulRouter == RR
         #
         #   drop in replacement for R(*u) Base method
         #   it automatically appends a set of routes to handle quasi-REST-type urls
         #
         #     class Index < RR()
         #     # rest methods
         #     end
         #
         # * Note: Include the () as in RR() if you do not include any url routes
         #   else Camping will not find it.
         # * would better if we could just override the R method and inject the changes. hints?
         #     def RR *u
         #        R(*u).send :include, SetupRestfulUrls #to setup the default routes
         #     end
         # * ..but elected not to override R where CRest toothpaste is not needed.
        def RR *u
            r=@r
            Class.new(CRestful::CRestClass) do
                @controller=name
                meta_def(:urls){u}
                meta_def(:inherited){|x|
                    n=x.name.demodulize.tableize
                    r=[]
                    r<<"/%s"        % n
                    r<<"/%s/(\\d+)" % n
                    r<<"/%s/(\\w+)" % n
                    r<<"/%s/(\\d+)/(\\w+)" % n
                    r<<"/%s/(\\.+)" % n
                    r.each{|rt| urls<<rt }
                    urls.uniq!
                    r<<x
                }
            end
        end
    end


    module MarkabyHelpers
        # Modifies Markaby's 'form' generator so that if a 'method' parameter
        # is supplied, a hidden '_method' input is automatically added.
        # -- ripped-off the mailing-list archives :-)

        def form(*args, &block)
            options = args[0] if args && args[0] && args[0].kind_of?(Hash)
            inside = capture( &block)
            if options && options.has_key?(:method)
                inside = input(:type => 'hidden', :name => '_method', :value => options[:method]) +
                inside
                if %w[put delete].include?(options[:method].to_s)
                    options[:method] = 'post'
                end
            end
            tag!(:form, options || args[0]) {inside}
        end
        # helper method for form-based a-like href links for POST type requests (PUT, DELETE, CREATE?)
        def _button(*args, &block)
            options=args.grep(Hash).pop || {}
            args-=[options]
            text=args.first #discard trailing array values
            text=block.call if block
            options[:action] = options[:href] && options.delete(:href)
            form(options) do
                input :type => 'submit', :value => text
            end
        end

        # helper method for form-based a-like href links for GET type requests (LIST, READ, {NEW})
        def _a(*args, &block)
            _button *[args.grep(Hash)[0].merge(:method=>'get')], &block
        end
    end
end

Camping::S << %{
    module Camping
        include Crestful
    end
}