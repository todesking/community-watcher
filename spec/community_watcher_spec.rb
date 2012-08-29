# -*- coding:utf-8 -*-

load File.join(File.dirname(__FILE__), '..', 'lib', 'community_watcher.rb')

class CommunityWatcher::Source::TestSource < CommunityWatcher::Source
end
class CommunityWatcher::Sink::TestSink < CommunityWatcher::Sink
end

describe CommunityWatcher::Config do
  before do
    @config_hash = YAML.load(<<-EOS)
source:
    source1:
        type: test_source
        category: aaa
        attr1: 1
        attr2: hogehoge
    source2:
        type: test_source
sink:
    sink1:
        type: test_sink
        category: bbb
    sink2:
        type: test_sink
        category: aaa
    EOS
  end

  subject { CommunityWatcher::Config.new(@config_hash) }

  describe 'Sourceの構築' do
    describe 'type' do
      it 'typeを元に生成するクラスを決定できる' do
        subject.sources['source1'].should be_a(CommunityWatcher::Source::TestSource)
      end
    end
    describe 'type(unknown)' do
      before do
        @config_with_invalid_typename = {'source'=>{'unk'=>{'type'=>'unk'}}}
      end
      it '未知のtypeが指定されてたら例外出る' do
        e = CommunityWatcher::Config.new(@config_with_invalid_typename) rescue $!
        e.should be_a(NameError)
        e.message.should =~ /Unk/
      end
    end
    describe 'config' do
      it 'Sourceのコンストラクタに渡るconfigには、設定されたすべての値が入っている' do
        subject.sources['source1'].config.should == subject.config['source']['source1']
      end
    end
    describe 'state' do
      before do
        subject.sources['source1'].state['hoge'] = 'fuga'
      end
      it 'Sourceのコンストラクタに渡るstateを変更すると、Config#stateの該当部分も変更される' do
        subject.state['source']['source1']['hoge'].should == 'fuga'
      end
    end
    describe 'id' do
      it 'IDが設定されている' do
        subject.sources['source1'].id.should == 'source1'
      end
    end
  end
  describe 'Sinkの構築' do
    it 'sourceと同じなので略'
  end
  describe 'Pipeの構築' do
  end
end

__END__

設定ファイルを元にグラフを構築できる
  ソースを構築できる
    typeがなかったらエラーになる
  同一カテゴリ名のソースとシンクがパイプでつながる
