# -*- coding:utf-8 -*-

require 'yaml'
require 'ostruct'
require 'active_support/inflector'

$: << File.join(File.dirname(__FILE__), '../vendor/typedocs/lib')
require 'typedocs'

module CommunityWatcher
  module Loggable
    private
    def info(str)
      puts "[#{self.class.name}:INFO] #{str}"
    end
  end

  class Config
    include Typedocs::DSL

    tdoc!"Hash ->"
    def initialize config_obj
      @config = config_obj
      @state = {
        'source' => {},
        'sink' => {},
      }

      @sources = create_objects CommunityWatcher::Source, config_obj['source']||{}, @state['source']
      @sinks = create_objects CommunityWatcher::Sink, config_obj['sink']||{}, @state['sink']
      @pipes = create_pipes
    end

    tdoc!"{source_id:String => Source}"
    attr_reader :sources

    tdoc!"{sink_id:String => Sink}"
    attr_reader :sinks

    tdoc!"Hash"
    attr_reader :config

    tdoc!"{'source' => {source_id:String => Hash}, 'sink' => {sink_id:String => Hash}}"
    attr_reader :state

    def flush
      # 同一ソースが複数のパイプにつながってると一度のflushで
      # 複数回fetchが呼ばれるが、そういうケースがあったら直します
      @pipes.each do|id, pipe|
        pipe.flush
      end
    end

    private
    tdoc!"Class -> config_root:{plugin_id:String => plugin_config:{key:String => *}} -> state_root:{plugin_id:String => state:Hash} -> {plugin_id:String => plugin:Source|Sink}"
    def create_objects namespace, config_root, state_root
      config_root.each_with_object({}) do|(id, obj_conf), result|
        type_name = obj_conf['type'].camelize
        type = namespace.const_get type_name
        obj_state = (state_root[id] ||= {})
        result[id] = type.new id, obj_conf, obj_state
      end
    end

    tdoc!"{pipe_id:String => Pipe}"
    def create_pipes
      pipes = {}
      @sources.each do|id, source|
        category = source.category
        if category
          pipe = (pipes[category] ||= Pipe.new category)
          pipe.add_source source
        end
      end
      @sinks.each do|id, sink|
        category = sink.category
        if category
          pipe = (pipes[category] ||= Pipe.new category)
          pipe.add_sink sink
        end
      end
      pipes
    end
  end

  class Node
    include Typedocs::DSL

    tdoc!"String -> {String => *} -> Hash ->"
    def initialize id, config, state
      @id = id
      @config = config
      @state = state
    end

    tdoc!"String"
    attr_reader :id

    tdoc!"{String => *}"
    attr_reader :config

    tdoc!"Hash"
    attr_reader :state

    # TODO: bug?
    # tdoc!"String"
    def category
      config['category']
    end
  end

  class Source < Node
    def pull
      []
    end
  end

  class Sink < Node
    def push message
    end
  end

  class Pipe
    include Typedocs::DSL
    include Loggable

    tdoc!"String ->"
    def initialize id
      @sources = []
      @sinks = []
      @dry_run = false
    end

    tdoc!"String"
    attr_reader :id
    attr_accessor :dry_run

    tdoc!""
    def flush
      @sources.each do|source|
        info "Updating: #{source.id}"
        recent_comments = source.pull
        info "  new comments: #{recent_comments.size}"
        recent_comments.each do|comment|
          info "  - #{comment.id} by #{comment.user_name}(#{comment.time})"
          @sinks.each do|sink|
            sink.push comment
          end
        end
      end
    end

    tdoc!"Source->"
    def add_source source
      @sources << source
      nil
    end

    tdoc!"Sink->"
    def add_sink sink
      @sinks << sink
      nil
    end
  end

  class Message
  end
end
