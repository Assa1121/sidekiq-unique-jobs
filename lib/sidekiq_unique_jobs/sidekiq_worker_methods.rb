# frozen_string_literal: true

module SidekiqUniqueJobs
  # Module with convenience methods for the Sidekiq::Worker class
  #
  # @author Mikael Henriksson <mikael@mhenrixon.com>
  module SidekiqWorkerMethods
    # Avoids duplicating worker_class.respond_to? in multiple places
    # @return [true, false]
    def worker_method_defined?(method_sym)
      worker_class.respond_to?(method_sym)
    end

    # Wraps #get_sidekiq_options to always work with a hash
    # @return [Hash] of the worker class sidekiq options
    def worker_options
      return {} unless sidekiq_worker_class?

      worker_class.get_sidekiq_options.deep_stringify_keys
    end

    # Tests that the
    # @return [true] if worker_class responds to get_sidekiq_options
    # @return [false] if worker_class does not respond to get_sidekiq_options
    def sidekiq_worker_class?
      worker_method_defined?(:get_sidekiq_options)
    end

    # The Sidekiq::Worker implementation
    # @return [Sidekiq::Worker]
    def worker_class
      @_worker_class ||= worker_class_constantize # rubocop:disable Naming/MemoizedInstanceVariableName
    end

    # The hook to call after a successful unlock
    # @return [Proc]
    def after_unlock_hook
      lambda do
        if @worker_class.respond_to?(:after_unlock)
          @worker_class.after_unlock # instance method in sidekiq v6
        elsif worker_class.respond_to?(:after_unlock)
          worker_class.after_unlock # class method regardless of sidekiq version
        end
      end
    end

    # Attempt to constantize a string worker_class argument, always
    # failing back to the original argument when the constant can't be found
    #
    # @return [Sidekiq::Worker]
    def worker_class_constantize(klazz = @worker_class)
      SidekiqUniqueJobs.constantize(klazz)
    rescue NameError => ex
      case ex.message
      when /uninitialized constant/
        klazz
      else
        raise
      end
    end

    #
    # Returns the default worker options from Sidekiq
    #
    #
    # @return [Hash<Symbol, Object>]
    #
    def default_worker_options
      Sidekiq.default_worker_options
    end
  end
end
