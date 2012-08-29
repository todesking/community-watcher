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
        'source' => {}
      }
      setup_sources config_obj['source']
    end

    attr_reader :sources
    attr_reader :config
    attr_reader :state

    private
    def setup_sources conf
      @sources = conf.each_with_object({}) do|(source_id, source_conf), result|
        type_name = source_conf['type'].camelize
        type = ::CommunityWatcher::Source.const_get type_name
        source_state = (state['source'][source_id] ||= {})
        result[source_id] = type.new  source_conf, source_state
      end
    end
  end

  class Source
    def initialize config, state
      @config = config
      @state = state
    end
    attr_reader :config
    attr_reader :state
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
