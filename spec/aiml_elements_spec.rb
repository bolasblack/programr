# coding: utf-8
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

describe ProgramR::ReplaceTag do
  let(:robot) { ProgramR::Facade.new }

  before do

  end

  it "can custom gender map" do
    robot.learn <<-AIML
<category>
  <pattern>gender test</pattern>
  <template>
    <gender>他和她</gender>
  </template>
</category>
    AIML
    ProgramR::Gender::Map['他和她'] = proc { '她和他' }
    expect(robot.get_reaction 'gender test').to eq '她和他'
  end
end
