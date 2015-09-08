require 'singleton.new'

class FakeEnvironment
  include Singleton

  def initialize
    @stage = {}
  end

  def get key
    @stage[key]
  end

  def set key, value
    @stage[key] = value
  end
end

describe ProgramR::AimlTag do
  let(:robot) { ProgramR::Facade.new }

  before do
    @origin_env = ProgramR::AimlTag.environment
    ProgramR::AimlTag.environment = FakeEnvironment.new
    robot.learn <<-AIML
<category>
  <pattern>set test</pattern>
  <template>
    <think><set_hello>world</set_hello></think>
  </template>
</category>
    AIML
  end

  after do
    ProgramR::AimlTag.environment = @origin_env
  end

  it "can change environment" do
    robot.get_reaction 'set test'
    expect(FakeEnvironment.new.get 'hello').to eq 'world'
  end
end
