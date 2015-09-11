
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

  let(:graph_master) { ProgramR::GraphMaster.new }
  let(:environment) { ProgramR::Environment.new ProgramR::History.instance }

  def response
    graph_master.get_reaction 'TEST', 'default', 'undef', []
  end

  describe '#learn' do
    let(:parsed_category) do
      mock_graph_master = MockGraphMaster.new
      parser = ProgramR::AimlParser.new mock_graph_master, environment
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
      parser = ProgramR::AimlParser.new graph_master, environment
      parser.parse aiml
    end

    it "reset the brain of graph_master" do
      expect(response).to eq ['success']
      graph_master.reset
      expect(response).to eq []
    end
  end
end
