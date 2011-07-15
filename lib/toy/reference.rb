module Toy
  class Reference
    attr_accessor :model, :name, :options

    def initialize(model, name, *args)
      @model   = model
      @name    = name.to_sym
      @options = args.extract_options!
      @type    = args.shift

      model.references[name] = self
      model.attribute(key, type.key_type)
      create_accessors
    end

    def type
      @type ||= name.to_s.classify.constantize
    end

    def key
      @key ||= :"#{name.to_s.singularize}_id"
    end

    def instance_variable
      @instance_variable ||= :"@_#{name}"
    end

    def new_proxy(owner)
      ReferenceProxy.new(self, owner)
    end

    def eql?(other)
      self.class.eql?(other.class) &&
        model == other.model &&
        name  == other.name
    end
    alias :== :eql?

    class ReferenceProxy
      extend Forwardable

      def_delegator :@reference, :type, :proxy_class
      def_delegator :@reference, :key, :proxy_key
      alias_method :proxy_respond_to?, :respond_to?
      instance_methods.each { |m| undef_method m unless m.to_s =~ /^(?:nil\?|send|object_id|to_a)$|^__|proxy_/ }

      def initialize(reference, owner)
        @reference, @owner = reference, owner
      end

      def proxy_owner
        @owner
      end

      def target
        return nil if target_id.blank?
        @target ||= proxy_class.get(target_id)
      end

      def reset
        @target = nil
      end

      def replace(record)
        if record.nil?
          reset
          self.target_id = nil
        else
          assert_type(record)
          @target = record
          self.target_id = record.id
        end
      end

      def create(attrs={})
        proxy_class.create(attrs).tap do |record|
          if record.persisted?
            self.target_id = record.id
            proxy_owner.save
            reset
          end
        end
      end

      def build(attrs={})
        proxy_class.new(attrs).tap do |record|
          self.target_id = record.id
          reset
        end
      end

      # Does the proxy or its \target respond to +symbol+?
      def respond_to?(*args)
        proxy_respond_to?(*args) || target.respond_to?(*args)
      end

      private
        def assert_type(record)
          unless record.instance_of?(proxy_class)
            raise(ArgumentError, "#{proxy_class} expected, but was #{record.class}")
          end
        end

        def target_id
          proxy_owner.send(proxy_key)
        end

        def target_id=(value)
          proxy_owner.send("#{proxy_key}=", value)
        end

        def method_missing(method, *args, &block)
          target.send(method, *args, &block)
        end
    end

    private
      def create_accessors
        model.class_eval """
          def #{name}
            #{instance_variable} ||= self.class.references[:#{name}].new_proxy(self).target
          end

          def #{name}=(record)
            self.class.references[:#{name}].new_proxy(self).replace(record)
            #{instance_variable} = record
          end

          def #{name}?
            !!#{name}
          end
          
          def build_#{name}(attrs={})
            self.class.references[:#{name}].new_proxy(self).build(attrs)
          end
          
          def create_#{name}(attrs={})
            self.class.references[:#{name}].new_proxy(self).create(attrs)
          end
          
          def reset_#{name}
            #{instance_variable} = nil
            self.class.references[:#{name}].new_proxy(self).reset
          end
        """
      end
  end
end