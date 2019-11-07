# frozen_string_literal: true
module Krane
  class TaskConfig
    attr_reader :context, :namespace, :logger

    def initialize(context, namespace, logger = nil)
      @context = context
      @namespace = namespace
      @logger = logger || FormattedLogger.build(@namespace, @context)
    end

    def global_kinds
      @global_kinds ||= begin
        cluster_resource_discoverer = ClusterResourceDiscovery.new(task_config: self)
        cluster_resource_discoverer.fetch_resources(only_globals: true).map { |g| g["kind"] }
      end
    end

    def namespaced_kinds
      @namespaced_kinds ||= begin
        cluster_resource_discoverer = ClusterResourceDiscovery.new(task_config: self)
        cluster_resource_discoverer.fetch_resources(only_namespaced: true).map { |g| g["kind"] }
      end
    end
  end
end
