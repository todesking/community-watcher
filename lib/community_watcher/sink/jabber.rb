# -*- coding:utf-8 -*-

require 'pit'
require 'xmpp4r'
require 'xmpp4r/muc'

class CommutyWatcher::Sink::Jabber < CommunityWatcher::Sink
  def initialize config, state
    nick = config['nick']
    room = config['room']
    user_info = Pit.get(config['pit-id'], require: {
      'jid'=> '通知に使うJabberアカウントのJID',
      'password'=> 'password',
    })
    @room_jid = ::Jabber::JID.new("#{room}/#{nick}")
    info "Connecting..."
    @client = ::Jabber::Client.new(::Jabber::JID.new(user_info['jid']))
    @client.connect
    @client.auth(user_info['password'])
    info "Success."

    @muc = ::Jabber::MUC::MUCClient.new(@client)
    @muc.join(@room_jid)
  end

  def push comment
    message = ::Jabber::Message.new(@room_jid, "#{comment.user_name}@#{comment.thread_title}:\n#{comment.body_text.gsub(/\n\n+/,"\n\n")}")
    @muc.send(message)
  end
  [1,2,3].each do|hoge|
    hogehoghe
  end
end
