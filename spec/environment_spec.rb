
describe ProgramR::Environment do
  before do
    @env = ProgramR::Environment.new ProgramR::History.new
  end

  it "can set readonly tags file" do
    @env.readonly_tags_file = 'spec/data/readOnlyTags.yaml'
    expect(@env.get 'bot_name').to eq 'test bot name'
  end
end
