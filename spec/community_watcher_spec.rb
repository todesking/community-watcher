# -*- coding:utf-8 -*-

load File.join(File.dirname(__FILE__), '..', 'lib', 'community_watcher.rb')

class CommunityWatcher::Source::TestSource < CommunityWatcher::Source
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
    EOS
  end

  subject { CommunityWatcher::Config.new(@config_hash) }

  describe 'Sourceの構築' do
    describe 'type' do
      it 'typeを元に生成するクラスを決定できる' do
        subject.sources['source1'].should be_a(CommunityWatcher::Source::TestSource)
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
  end
  describe 'Sinkの構築' do
  end
end

__END__

設定ファイルを元にグラフを構築できる
  ソースを構築できる
    typeがなかったらエラーになる
  シンクを構築できる
    コンストラクタにconfig,stateを渡せる
    stateの変更は大本に反映できる
  同一カテゴリ名のソースとシンクがパイプでつながる
