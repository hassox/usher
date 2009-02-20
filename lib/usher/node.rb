class Usher

  class Node
    attr_reader :value, :parent, :lookup
    attr_accessor :terminates

    def depth
      unless @depth
        @depth = 0
        p = self
        while not (p = p.parent).nil?
          @depth += 1
        end
      end
      @depth
    end
    
    def self.root
      self.new(nil, nil)
    end

    def initialize(parent, value)
      @parent = parent
      @value = value
      @lookup = Hash.new
    end

    def has_globber?
      if @has_globber.nil?
        @has_globber = find_parent{|p| p.value && p.value.is_a?(Route::Variable)}
      end
      @has_globber
    end

    def terminates?
      @terminates
    end

    def find_parent(&blk)
      if @parent.nil?
        nil
      elsif yield @parent
        @parent
      else #keep searching
        @parent.find_parent(&blk)
      end
    end

    def add(route)
      path = route.path.dup
      current_node = self
      until path.size.zero?
        key = path.shift
        lookup_key = key.is_a?(Route::Variable) ? nil : key
        unless target_node = current_node.lookup[lookup_key]
          target_node = current_node.lookup[lookup_key] = Node.new(current_node, key)
        end
        current_node = target_node
      end
      current_node.terminates = route
      current_node
    end

    def find(path, params = [])
      if path.size.zero?
        return [terminates, params] if terminates?
        raise "could not recognize route" 
      end

      part = path.shift
      if next_part = @lookup[part]
        next_part.find(path, params)
      elsif part.is_a?(Route::Method) && next_part = @lookup[Route::Method::Any]
        next_part.find(path, params)
      elsif next_part = @lookup[nil]
        if next_part.value.is_a?(Route::Variable)
          raise "#{part} does not conform to #{next_part.value.validator}" if next_part.value.validator && (not next_part.value.validator === part)
          case next_part.value.type
          when :*
            params << [next_part.value.name, []]
            params.last.last << part unless next_part.is_a?(Route::Seperator)
          when :':'
            params << [next_part.value.name, part]
          end
        end
        next_part.find(path, params)
      elsif has_globber? && p = find_parent{|p| !p.is_a?(Route::Seperator)} && p.value.is_a?(Route::Variable) && p.value.type == :*
        params.last.last << part unless part.is_a?(Route::Seperator)
        find(path, params)
      else
        raise "did not recognize #{part} in #{@lookup.keys.inspect}"
      end
    end

  end
end