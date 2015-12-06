# coding: utf-8

class MockGraphmaster
  attr_reader :learned

  def initialize
    @learned = []
  end

  def learn category
    @learned << category
  end
end

describe ProgramR::Graphmaster do
  aiml = <<-AIML
<category>
  <pattern>test</pattern>
  <template>success</template>
</category>
  AIML

  let(:history) { ProgramR::History.new }
  let(:graphmaster) { ProgramR::Graphmaster.new }
  let(:environment) { ProgramR::Environment.new history }

  def response
    graphmaster.get_reaction 'TEST', 'default', 'undef', []
  end

  describe '#learn' do
    let(:parsed_category) do
      mock_graphmaster = MockGraphmaster.new
      parser = ProgramR::AimlParser.new mock_graphmaster, environment, history
      parser.parse aiml
      mock_graphmaster.learned.first
    end

    it "learn category" do
      graphmaster.learn parsed_category
      expect(response).to eq ['success']
    end
  end

  describe '#reset' do
    before do
      parser = ProgramR::AimlParser.new graphmaster, environment, history
      parser.parse aiml
    end

    it "reset the brain of graphmaster" do
      expect(response).to eq ['success']
      graphmaster.reset
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
      graphmaster.register_segmenter(:zh)  do |segments|
        segments.map{ |segment| segment.split '' }.flatten
      end
      graphmaster.instance_eval { @graph = fakeNode }

      input = '你好，这是一个测试'
      graphmaster.get_reaction input, [], [], []
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
      graphmaster.register_segmenter(:zh) do |segments|
        segments.map{ |segment| segment.split '' }.flatten
      end
      graphmaster.instance_eval { @graph = fakeNode }

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

      graphmaster.learn cn_category
      expect(fakeNode.last_path[0, pattern.length]).to eq pattern.split ''
      graphmaster.learn en_category
      expect(fakeNode.last_path[0, 1]).to eq [pattern]
    end
  end
end
