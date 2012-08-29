# -*- coding:utf-8 -*-

require 'active_support/inflector'

module CommunityWatcher
  module Loggable
    private
    def info(str)
      puts "[#{self.class.name}:INFO] #{str}"
    end
  end

  class Config
    def initialize config_obj
      @config = config_obj
      @state = {
        'source' => {},
        'sink' => {},
      }

      @sources = create_objects CommunityWatcher::Source, config_obj['source']||{}, @state['source']
      @sinks = create_objects CommunityWatcher::Sink, config_obj['sink']||{}, @state['sink']
    end

    attr_reader :sources
    attr_reader :sinks
    attr_reader :config
    attr_reader :state

    private
    def create_objects namespace, config_root, state_root
      config_root.each_with_object({}) do|(id, obj_conf), result|
        type_name = obj_conf['type'].camelize
        type = namespace.const_get type_name
        obj_state = (state_root[id] ||= {})
        result[id] = type.new id, obj_conf, obj_state
      end
    end
  end

  class Node
    def initialize id, config, state
      @id = id
      @config = config
      @state = state
    end

    attr_reader :id
    attr_reader :config
    attr_reader :state
  end

  class Source < Node
  end

  class Sink < Node
  end

  class Pipe
    include Loggable

    def initialize
      @sources = []
      @sinks = []
      @dry_run = false
    end

    attr_accessor :dry_run

    def flush
      @sources.each do|source|
        info "Updating: #{source.id}"
        recent_comments = source.fetch_recent_comments
        info "  new comments: #{recent_comments.size}"
        recent_comments.each do|comment|
          info "  - #{comment.id} by #{comment.user_name}(#{comment.time})"
          @sinks.each do|sink|
            sink.notify comment
          end
        end
      end
    end

    def add_source source
      @sources << source
      nil
    end

    def add_sink sink
      @sinks << sink
      nil
    end
  end
end
