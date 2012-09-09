# -*- coding:utf-8 -*-

class CommunityWatcher::Source::Gree < CommunityWatcher::Source
  def initialize config, state
    super

    @state.merge!(
      last_comment_id: 0
    )

    user_info = Pit.get(config['pit-id'], require: {
      'mail'=> 'データ取得に使うGREEアカウントのメアド',
      'password'=> 'password',
    })

    @fetcher = GREE::Community::Fetcher.new(
      user_info['mail'],
      user_info['password']
    )

    @threads = config['threads'].map{|thread_id|
      GREE::Community::Thread.new(thread_id)
    }
  end

  def pull
    update_threads!
    comments = @threads.flat_map{|thread|
      thread.recent_comments.select{|c| c.id > @state[:last_comment_id]}.map{|c|
        OpenStruct.new(
          id: c.id,
          user_name: c.user_name,
          thread_title: thread.title,
          body_text: c.body_text,
          time: c.time,
        )
      }
    }
    @state[:last_comment_id] = comments.map(&:id).max || @state[:last_comment_id]
    comments
  end

  private
  def update_threads!
    info 'Updating threads'
    @threads.each{|t|
      t.fetch(@fetcher)
      info "  - #{t.id} #{t.title}"
    }
  end
end
