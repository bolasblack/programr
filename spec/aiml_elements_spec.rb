# coding: utf-8

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
