# coding: utf-8

class MockGraphMaster
  attr_reader :learned

  def initialize
    @learned = []
  end

  def learn category
    @learned << category
  end
end

describe ProgramR::GraphMaster do
  aiml = <<-AIML
<category>
  <pattern>test</pattern>
  <template>success</template>
</category>
  AIML

  let(:history) { ProgramR::History.new }
  let(:graph_master) { ProgramR::GraphMaster.new }
  let(:environment) { ProgramR::Environment.new history }

  def response
    graph_master.get_reaction 'TEST', 'default', 'undef', []
  end

  describe '#learn' do
    let(:parsed_category) do
      mock_graph_master = MockGraphMaster.new
      parser = ProgramR::AimlParser.new mock_graph_master, environment, history
      parser.parse aiml
      mock_graph_master.learned.first
    end

    it "learn category" do
      graph_master.learn parsed_category
      expect(response).to eq ['success']
    end
  end

  describe '#reset' do
    before do
      parser = ProgramR::AimlParser.new graph_master, environment, history
      parser.parse aiml
    end

    it "reset the brain of graph_master" do
      expect(response).to eq ['success']
      graph_master.reset
      expect(response).to eq []
    end
  end

  describe '#register_segmenter' do
    it 'split input stimula' do
      class FakeNode
        attr_reader :last_path

        def get_template path, starGreedy
          @last_path = path
          ProgramR::Template.new
        end
      end

      fakeNode = FakeNode.new
      graph_master.register_segmenter(:zh)  do |segments|
        segments.map{ |segment| segment.split '' }.flatten
      end
      graph_master.instance_eval { @graph = fakeNode }

      input = '你好，这是一个测试'
      graph_master.get_reaction input, [], [], []
      expect(fakeNode.last_path[0, input.length]).to eq input.split ''
    end

    it 'split pattern text in aiml when language matched' do
      class FakeNode
        attr_reader :last_path

        def learn category, path
          @last_path = path
        end
      end

      fakeNode = FakeNode.new
      graph_master.register_segmenter(:zh) do |segments|
        segments.map{ |segment| segment.split '' }.flatten
      end
      graph_master.instance_eval { @graph = fakeNode }

      pattern = '你好，这是一个测试'

      cn_category = ProgramR::Category.new
      cn_category.language = :zh
      cn_category.add_pattern pattern
      cn_category.template = ProgramR::Template.new
      cn_category.template.append 'hello world'

      en_category = ProgramR::Category.new
      en_category.language = :en
      en_category.add_pattern pattern
      en_category.template = ProgramR::Template.new
      en_category.template.append 'hello world'

      graph_master.learn cn_category
      expect(fakeNode.last_path[0, pattern.length]).to eq pattern.split ''
      graph_master.learn en_category
      expect(fakeNode.last_path[0, 1]).to eq [pattern]
    end
  end
end
