require File.join(File.dirname(__FILE__), 'route', 'path')
require File.join(File.dirname(__FILE__), 'route', 'util')
require File.join(File.dirname(__FILE__), 'route', 'variable')
require File.join(File.dirname(__FILE__), 'route', 'request_method')

class Usher
  class Route
    attr_reader :paths, :requirements, :conditions, :destination, :named, :generate_with
    
    GenerateWith = Struct.new(:scheme, :port, :host)
    
    def initialize(parsed_paths, router, conditions, requirements, default_values, generate_with) # :nodoc:
      @router = router
      @requirements = requirements
      @conditions = conditions
      @default_values = default_values
      @generate_with = GenerateWith.new(generate_with[:scheme], generate_with[:port], generate_with[:host]) if generate_with
      @paths = parsed_paths.collect {|path| Path.new(self, path)}
    end
    
    def grapher
      unless @grapher
        @grapher = Grapher.new
        @grapher.add_route(self)
      end
      @grapher
    end

    def find_matching_path(params)
      @paths.size == 1 ? @paths.first : grapher.find_matching_path(params)
    end
    
    
    # Sets +options+ on a route. Returns +self+.
    #   
    #   Request = Struct.new(:path)
    #   set = Usher.new
    #   route = set.add_route('/test')
    #   route.to(:controller => 'testing', :action => 'index')
    #   set.recognize(Request.new('/test')).first.params => {:controller => 'testing', :action => 'index'}
    def to(options = nil, &block)
      @destination = (block_given? ? block : options)
      self
    end

    # Sets route as referenceable from +name+. Returns +self+.
    #   
    #   set = Usher.new
    #   route = set.add_route('/test').name(:route)
    #   set.generate_url(:route) => '/test'
    def name(name)
      @named = name
      @router.name(name, self)
      self
    end

  end
end
