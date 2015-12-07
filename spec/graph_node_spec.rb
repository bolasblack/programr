require File.join(File.dirname(__FILE__), './utils/fake_graphmaster')

def parse_category category_aiml
  history = ProgramR::History.new
  environment = ProgramR::Environment.new history
  fake_graphmaster = FakeGraphmaster.new
  parser = ProgramR::AimlParser.new fake_graphmaster, environment, history
  parser.parse category_aiml
  fake_graphmaster.learned.first
end

def generate_aiml template
  <<-AIML
<category>
  <pattern>test</pattern>
  <template>#{template}</template>
</category>
  AIML
end

describe ProgramR::GraphNode do
  let(:node) { ProgramR::GraphNode.new }

  describe '#learn' do
    it 'create children for each word in path' do
      node.learn parse_category(generate_aiml 'success'), ['a', 'b']
      expect(node.children['a'].children['b'].template.value).to eq ['success']
    end
  end

  describe '#get_template' do
    shared_examples '#get_template specs' do |opts|
      it 'support full word matcher' do
        node.learn parse_category(generate_aiml 'success'), 'abcdefg'.split('').concat(opts[:path_suffix])
        matched = []
        expect(node.get_template(opts[:input_path], matched).value).to eq ['success']
        expect(matched).to eq [] + opts[:matched_suffix]
      end

      it 'support star matcher' do
        node.learn parse_category(generate_aiml 'success'), 'a*g'.split('').concat(opts[:path_suffix])
        matched = []
        expect(node.get_template(opts[:input_path], matched).value).to eq ['success']
        expect(matched).to eq ['<star>', 'b', 'c', 'd', 'e', 'f'] + opts[:matched_suffix]
      end

      it 'support multipie star matcher' do
        node.learn parse_category(generate_aiml 'success'), 'a*cd*g'.split('').concat(opts[:path_suffix])
        matched = []
        expect(node.get_template(opts[:input_path], matched).value).to eq ['success']
        expect(matched).to eq ['<star>', 'b', '<star>', 'e', 'f'] + opts[:matched_suffix]
      end

      it 'try exact word matcher first, then try star matcher if failed' do
        node.learn parse_category(generate_aiml 'success'), 'a*g'.split('').concat(opts[:path_suffix])
        node.learn parse_category(generate_aiml 'failed'), 'abk*g'.split('').concat(opts[:path_suffix])
        matched = []
        expect(node.get_template(opts[:input_path], matched).value).to eq ['success']
        expect(matched).to eq ['<star>', 'b', 'c', 'd', 'e', 'f'] + opts[:matched_suffix]
      end

      it 'make star matcher match at least one word' do
        node.learn parse_category(generate_aiml 'success'), 'a******g'.split('').concat(opts[:path_suffix])
        matched = []
        expect(node.get_template opts[:input_path], matched).to be_nil
        expect(matched).to eq []
      end

      it 'make star matcher non-greedy' do
        node.learn parse_category(generate_aiml 'success'), 'a**g'.split('').concat(opts[:path_suffix])
        matched = []
        expect(node.get_template(opts[:input_path], matched).value).to eq ['success']
        expect(matched).to eq ['<star>', 'b', '<star>', 'c', 'd', 'e', 'f'] + opts[:matched_suffix]
      end
    end

    context 'without that and topic' do
      include_examples(
        '#get_template specs',
        input_path: ['a', 'b', 'c', 'd', 'e', 'f', 'g', ProgramR::GraphMark::THAT, 'undef', ProgramR::GraphMark::TOPIC, 'undef'],
        path_suffix: [],
        matched_suffix: []
      )
    end

    context 'with that' do
      include_examples(
        '#get_template specs',
        input_path: ['a', 'b', 'c', 'd', 'e', 'f', 'g', ProgramR::GraphMark::THAT, 'c', 'd', 'g', ProgramR::GraphMark::TOPIC, 'undef'],
        path_suffix: [ProgramR::GraphMark::THAT, 'c', 'd', 'g'],
        matched_suffix: []
      )
    end

    context 'with star existed that' do
      include_examples(
        '#get_template specs',
        input_path: ['a', 'b', 'c', 'd', 'e', 'f', 'g', ProgramR::GraphMark::THAT, 'c', 'd', 'g', ProgramR::GraphMark::TOPIC, 'undef'],
        path_suffix: [ProgramR::GraphMark::THAT, 'c', '*', 'g'],
        matched_suffix: [ProgramR::GraphMark::THAT, '<star>', 'd']
      )
    end

    context 'with multipie star existed that' do
      include_examples(
        '#get_template specs',
        input_path: ['a', 'b', 'c', 'd', 'e', 'f', 'g', ProgramR::GraphMark::THAT, 'c', 'd', 'f', 'e', 'g', ProgramR::GraphMark::TOPIC, 'undef'],
        path_suffix: [ProgramR::GraphMark::THAT, 'c', '*', '*', 'g'],
        matched_suffix: [ProgramR::GraphMark::THAT, '<star>', 'd', '<star>', 'f', 'e']
      )
    end

    context 'with topic' do
      include_examples(
        '#get_template specs',
        input_path: ['a', 'b', 'c', 'd', 'e', 'f', 'g', ProgramR::GraphMark::THAT, 'undef', ProgramR::GraphMark::TOPIC, 'c', 'd', 'g'],
        path_suffix: [ProgramR::GraphMark::TOPIC, 'c', 'd', 'g'],
        matched_suffix: []
      )
    end

    context 'with star existed topic' do
      include_examples(
        '#get_template specs',
        input_path: ['a', 'b', 'c', 'd', 'e', 'f', 'g', ProgramR::GraphMark::THAT, 'undef', ProgramR::GraphMark::TOPIC, 'c', 'd', 'g'],
        path_suffix: [ProgramR::GraphMark::TOPIC, 'c', '*', 'g'],
        matched_suffix: [ProgramR::GraphMark::TOPIC, '<star>', 'd']
      )
    end

    context 'with multipie star existed topic' do
      include_examples(
        '#get_template specs',
        input_path: ['a', 'b', 'c', 'd', 'e', 'f', 'g', ProgramR::GraphMark::THAT, 'undef', ProgramR::GraphMark::TOPIC, 'c', 'd', 'f', 'e', 'g'],
        path_suffix: [ProgramR::GraphMark::TOPIC, 'c', '*', '*', 'g'],
        matched_suffix: [ProgramR::GraphMark::TOPIC, '<star>', 'd', '<star>', 'f', 'e']
      )
    end

    context 'with that and topic' do
      include_examples(
        '#get_template specs',
        input_path: ['a', 'b', 'c', 'd', 'e', 'f', 'g', ProgramR::GraphMark::THAT, 'c', 'd', 'g', ProgramR::GraphMark::TOPIC, 'c', 'd', 'g'],
        path_suffix: [ProgramR::GraphMark::THAT, 'c', 'd', 'g', ProgramR::GraphMark::TOPIC, 'c', 'd', 'g'],
        matched_suffix: []
      )
    end

    context 'with star existed that and topic' do
      include_examples(
        '#get_template specs',
        input_path: ['a', 'b', 'c', 'd', 'e', 'f', 'g', ProgramR::GraphMark::THAT, 'c', 'd', 'g', ProgramR::GraphMark::TOPIC, 'c', 'd', 'g'],
        path_suffix: [ProgramR::GraphMark::THAT, 'c', '*', 'g', ProgramR::GraphMark::TOPIC, 'c', '*', 'g'],
        matched_suffix: [ProgramR::GraphMark::THAT, '<star>', 'd', ProgramR::GraphMark::TOPIC, '<star>', 'd']
      )
    end

    context 'with multipie star existed that and topic' do
      include_examples(
        '#get_template specs',
        input_path: ['a', 'b', 'c', 'd', 'e', 'f', 'g', ProgramR::GraphMark::THAT, 'c', 'd', 'f', 'e', 'g', ProgramR::GraphMark::TOPIC, 'c', 'd', 'f', 'e', 'g'],
        path_suffix: [ProgramR::GraphMark::THAT, 'c', '*', '*', 'g', ProgramR::GraphMark::TOPIC, 'c', '*', '*', 'g'],
        matched_suffix: [ProgramR::GraphMark::THAT, '<star>', 'd', '<star>', 'f', 'e', ProgramR::GraphMark::TOPIC, '<star>', 'd', '<star>', 'f', 'e']
      )
    end
  end
end
