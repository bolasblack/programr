# coding: utf-8
require 'securerandom'
require File.join(File.dirname(__FILE__), './utils/fake_environment')

describe ProgramR::Facade do
  let(:robot) do
    robot = ProgramR::Facade.new
    robot.environment.readonly_tags_file = 'spec/data/readOnlyTags.yaml'
    robot
  end

  after { robot.reset }

  it 'can custon environment' do
    robot = ProgramR::Facade.new FakeEnvironment
    robot.learn <<-AIML
 <category>
   <pattern>set test</pattern>
   <template>
     <think><set_hello>world</set_hello></think>
   </template>
 </category>
     AIML
    robot.get_reaction 'set test'
    expect(robot.environment.get 'hello').to eq 'world'
  end

  describe '#learn' do
    it "can read plain aiml" do
      pattern = SecureRandom.hex
      result = SecureRandom.hex

      robot.learn <<-AIML
<category>
  <pattern>#{pattern}</pattern>
  <template>#{result}</template>
</category>
      AIML

      expect(robot.get_reaction pattern).to eq result
    end

    it "can read aiml folder" do
      robot.learn ['spec/data/for_learn_test']
      expect(robot.get_reaction 'single file').to eq 'OK'
      expect(robot.get_reaction 'in dir').to eq 'OK'
      expect(robot.get_reaction 'in sub dir').to eq 'OK'
      expect(robot.get_reaction 'badfile').to eq ''
    end
  end

  describe '#get_reaction' do
    before { robot.learn ['spec/data/facade.aiml'] }

    shared_examples 'alice' do |opt = {}|
      if opt[:in_test]
        message = "support #{opt[:in_test]}"
      else
        message = "can handle message #{opt[:with_stimula]}"
      end

      def bind_proc proc, instance
        instance.define_singleton_method :_, &proc
        fn = instance.method(:_).unbind
        instance.instance_eval { undef :_ }
        fn.bind instance
      end

      it message do
        bind_proc(opt[:prepare], self).call unless opt[:prepare].nil?
        robot.learn aiml if self.respond_to? :aiml
        response = opt[:response].is_a?(Proc) ? opt[:response].call : opt[:response]
        expect(robot.get_reaction(opt[:with_stimula])).to eq response
        bind_proc(opt[:asserts], self).call response unless opt[:asserts].nil?
      end
    end

    describe 'with paratactic condition' do
      before { robot.learn ['spec/data/condition.aiml'] }
      it_behaves_like 'alice', response: 'You sound very handsome.', with_stimula: 'I AM BROWN', in_test: 'normal case'
      it_behaves_like 'alice', response: 'You sound very handsome.', with_stimula: 'I AM CYAN', in_test: 'item value include start'
      it_behaves_like 'alice', response: 'You sound very attractive.', with_stimula: 'I AM GREEN', in_test: 'not exist attribute'
      it_behaves_like 'alice', response: 'You sound very attractive.', with_stimula: 'I AM PINK', in_test: 'null value'
    end

    describe 'with condition list' do
      before { robot.learn ['spec/data/condition.aiml'] }
      it_behaves_like 'alice', response: 'You sound very handsome.', with_stimula: 'I AM RED', in_test: 'normal case'
      it_behaves_like 'alice', response: 'You sound very handsome.', with_stimula: 'I AM BLOND', in_test: 'item value include star'
      it_behaves_like 'alice', response: 'You sound very handsome.', with_stimula: 'I AM BLACK', in_test: 'switch style'
      it_behaves_like 'alice', response: 'You sound very handsome.', with_stimula: 'I AM WHITE', in_test: 'not exist attribute'
      it_behaves_like 'alice', response: 'You sound very attractive.', with_stimula: 'I AM BLUE', in_test: 'null value'
      it_behaves_like 'alice', response: 'You sound very nice.', with_stimula: 'I AM GRAY', in_test: 'default item'
    end

    describe 'with srai tag' do
      before { robot.learn ['spec/data/srai.aiml'] }
      it_behaves_like 'alice', response: 'world', with_stimula: 'test1', in_test: 'normal case'
      it_behaves_like 'alice', response: 'world', with_stimula: 'test2', in_test: 'included by other tag'
    end

    describe 'with set tag' do
      before { robot.learn ['spec/data/set.aiml'] }
      it_behaves_like 'alice', response: 'male.female.female', with_stimula:'test set', in_test: 'normal case'
      it_behaves_like 'alice', response: "Got it, INPUT", with_stimula: 'input', in_test: 'set star matched content'
    end

    it_behaves_like 'alice', response: 'are you never tired to do the same things every day?', with_stimula:'question test' do srand(2) end

    it_behaves_like 'alice', response: 'test succeeded', with_stimula: 'srai test', asserts: -> (response) do
      expect(robot.history.topic).to eq 'WORK'
    end

    it_behaves_like 'alice', response: 'new test succeeded', with_stimula: 'atomic test', in_test: 'TOPIC', prepare: -> { robot.history.topic = 'WORK' }
    it_behaves_like 'alice', response: 'that test 1', with_stimula: 'that test',  in_test: 'THAT 1', prepare: -> { robot.history.update_response 'NEW TEST SUCCEEDED' }
    it_behaves_like 'alice', response: 'that test 2', with_stimula:'that test', in_test: "THAT 2", prepare: -> { robot.history.update_response 'THAT TEST 1' }
    it_behaves_like 'alice', response: 'topic star test succeeded OK', with_stimula:'atomic test', in_test: "STAR TOPIC", prepare: -> { robot.history.topic = 'OK GAME' }
    it_behaves_like 'alice', response: 'the UPPERCASE test', with_stimula:'uppercase test'
    it_behaves_like 'alice', response: 'the lowercase test', with_stimula:'LOWERCASE TEST'
    it_behaves_like 'alice', response: -> { Date.today.to_s }, with_stimula:'DATE TEST'
    it_behaves_like 'alice', response: -> { 'time:' + `date`.chomp }, with_stimula:'SYSTEM TEST'
    it_behaves_like 'alice', response: -> { ProgramR::Category.cardinality.to_s }, with_stimula:'SIZE TEST'
    it_behaves_like 'alice', response: "TEST SPACE", with_stimula:"SPACE TEST"
    it_behaves_like 'alice', response: 'test bot name', with_stimula:'get test 1'
    it_behaves_like 'alice', response: 'TEST SPACE', with_stimula:'justbeforethat tag test', prepare: -> do
      robot.history.update_response 'TEST SPACE'
      robot.history.update_response 'padding'
    end
    it_behaves_like 'alice', response: 'TEST SPACE', with_stimula:'that tag test', prepare: -> do
      robot.history.update_response 'TEST SPACE'
    end
    it_behaves_like 'alice', response: 'localhost', with_stimula:'get test 2'
    it_behaves_like 'alice', response: 'ok.', with_stimula:'think test. i am male'
    it_behaves_like 'alice', response: 'The sentence test', with_stimula:'sentence test'
    it_behaves_like 'alice', response: 'The Formal Test', with_stimula:'formal test'
    it_behaves_like 'alice', response: 'A', with_stimula:'random test'
    it_behaves_like 'alice', response: 'RANDOM TEST.FORMAL TEST', with_stimula:'test input', prepare: -> do
      robot.history.update_stimula 'FORMAL TEST'
      robot.history.update_stimula 'RANDOM TEST'
    end
    it_behaves_like 'alice', response: 'she told to him to take a hike but her ego was too much for him', with_stimula:'test gender'
    it_behaves_like 'alice', response: 'she TOLD to him', with_stimula:'test gender wrap star he told to her'
    it_behaves_like 'alice', response: 'he TOLD MAURO EVERYTHING OK WITH his PROBLEM BUT i ANSWERS NO', with_stimula:'test person wrap star i told mauro everything ok with my problem but he answers no'
    it_behaves_like 'alice', response: 'i say everything ok to you', with_stimula:'you say everything ok to me'
    it_behaves_like 'alice', response: 'star wins', with_stimula:'This is her'
    it_behaves_like 'alice', response: 'underscore wins', with_stimula:'This is you'
    it_behaves_like 'alice', response: 'explicit pattern wins', with_stimula:'This is clearly you'
    it_behaves_like 'alice', response: 'first star is ARE NEAT AND second star is GOOD AS', with_stimula:'These are neat and clearly good as them'

    describe 'thatstar tag' do
      it_behaves_like 'alice', response: 'ALSO MINE IS AC MILAN', with_stimula:'AC milan', prepare: -> do
        robot.history.update_response 'WHAT IS YOUR FAVORITE FOOTBALL TEAM'
      end
      it_behaves_like 'alice', response: 'ok yes ALSO MINE IS AC MILAN', with_stimula: 'yes AC milan', prepare: -> do
        robot.history.update_response 'WHAT IS YOUR FAVORITE FOOTBALL TEAM'
      end
    end

  end
end
