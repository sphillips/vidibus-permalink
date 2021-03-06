module Vidibus
  module Permalink
    class Dispatcher

      class PathError < StandardError; end

      # Initialize a new Dispatcher instance.
      # Provide an absolute +path+ to be dispatched.
      def initialize(path, options = {})
        self.path = path
        @scope = options[:scope]
      end

      # Returns the path to dispatch.
      def path
        @path
      end

      # Sets path to dispatch
      def path=(value)
        raise PathError.new("Path must be absolute.") unless value.match(/^\//)
        @path = value
      end

      # Returns parts of the path.
      # Ignores file extension and request params
      def parts
        @parts ||= path.gsub(/(\.[^\/]+)?(\?.*)?$/, "").scan(/[^?\/]+/)
      end

      # Returns permalink objects matching the parts.
      def objects
        @objects ||= resolve_path
      end

      # Returns true if all parts could be resolved.
      def found?
        @is_found ||= begin
          !objects.include?(nil)
        end
      end

      # Returns true if any part does not reflect
      # the current permalink of the underlying linkable.
      def redirect?
        @is_redirect ||= begin
          return unless found?
          redirectables.any?
        end
      end

      # Returns the path to redirect to, if any.
      def redirect_path
        @redirect_path ||= begin
          return unless redirect?
          "/" << current_parts.join("/")
        end
      end

      private

      def resolve_path
        results = ::Permalink.for_scope(@scope).any_in(value: parts)
        links = Array.new(parts.length)
        done = {}
        for result in results
          if i = parts.index(result.value)
            key = "#{result.linkable_type}##{result.linkable_id}"
            next if done[key]
            links[i] = result
            done[key] = true
          end
        end
        links
      end

      # Returns an array containing the current permalinks of all objects.
      def current_parts
        objects.map { |o| o.current.value }
      end

      def redirectables
        objects.select { |o| !o.current? }
      end
    end
  end
end
