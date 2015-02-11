
describe ProgramR::Environment do
  before do
    @env = ProgramR::Environment.new
  end

  it "can set readonly tags file" do
    ProgramR::Environment.readonly_tags_file = 'spec/data/readOnlyTags.yaml'
    expect(@env.get 'bot_name').to eq 'test bot name'
  end
end
