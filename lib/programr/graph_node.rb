# coding: utf-8

module ProgramR
  class GraphNode
    attr_reader :children, :template

    MATCHERS = %w{_ *}

    def initialize
      @template = nil
      @children = {}
    end

    # @param category [Category]
    # @param path [Array<String>]
    def learn category, path
      branch = path.first
      # Only the tail node has @template
      return @template = category.template if branch.nil?
      (@children[branch] ||= GraphNode.new).learn(category, array_tail(path))
    end

    def get_template_with_matcher input_path, matched, matcher
      current_branch = input_path.first
      if input_path.empty?
        @template
      elsif matcher_ending? input_path, matched
        new_matched = []
        if template = get_template_without_matcher(input_path, new_matched)
          matched.concat new_matched
          template
        end
      else
        matched << current_branch
        get_template_with_matcher array_tail(input_path), matched, matcher
      end
    end

    def get_template_without_matcher input_path, matched, current_section = nil
      current_branch = input_path.first
      if current_branch == GraphMark::THAT
        current_section = GraphMark::THAT
      elsif current_branch == GraphMark::TOPIC
        current_section = GraphMark::TOPIC
      end

      if input_path.empty? or rest_section_not_exists_in_tree?(input_path)
        template = @template
      elsif @children.has_key? current_branch
        template = @children[current_branch].get_template_without_matcher(array_tail(input_path), matched, current_section)
      elsif current_branch == GraphMark::THAT
        skip_result = skip_that_section current_branch, input_path
        template = get_template_without_matcher skip_result[:input_path], matched
      end

      # if any node have @template, it must be an ending of a branch even
      # though it have @children
      return template if template

      MATCHERS.each do |matcher|
        new_matched = [current_branch]
        next unless @children.has_key? matcher
        next unless template = @children[matcher].get_template_with_matcher(array_tail(input_path), new_matched, matcher)
        matched.concat (current_section ? [current_section, '<star>'] : ['<star>']) + new_matched
        return template
      end

      nil
    end

    # Get template for input by the matching algorithm
    #
    # Open https://docs.google.com/document/d/1wNT25hJRyupcG51aO89UcQEiG-HkXRXusukADpFnDs4/pub
    # and search `7. AIML Pattern Matching` to get information about the matching algorithm
    #
    # This function will only return `nil` or `@template` if path ending,
    #
    # @param input [Array<String>]
    # @param matched [Array<String>]
    def get_template input, matched
      get_template_without_matcher clean_undef_section(input), matched
    end

    # @!method inspect_node
    def inspect_node branch = nil, indent_level = 0
      line_head = [0, 1].include?(indent_level) ? '' : '┃ ' * (indent_level - 2) + '┣ '
      line_content = (branch ? branch.to_s : '') + (@template ? ": [#{@template.inspect}]" : '')
      line_tail = indent_level == 0 ? '' : "\n"
      str = line_head + line_content + line_tail
      @children.each_key do |child_branch|
        str += @children[child_branch].inspect_node(child_branch, indent_level + 1)
      end
      str
    end

    private

    def array_tail array
      array.slice(1, array.length - 1)
    end

    def clean_undef_section input_path
      splited = input_path.reduce({input: [], that: [], topic: [], current_section: nil}) do |memo, part|
        if GraphMark::ALL.include? part
          memo[:current_section] = part
          next memo
        end

        if not memo[:current_section]
          memo[:input].push part
        elsif memo[:current_section] == GraphMark::THAT and part != 'undef'
          memo[:that].push part
        elsif memo[:current_section] == GraphMark::TOPIC and part != 'undef'
          memo[:topic].push part
        end

        memo
      end

      result = splited[:input]
      result.concat [GraphMark::THAT] + splited[:that] if not splited[:that].empty?
      result.concat [GraphMark::TOPIC] + splited[:topic] if not splited[:topic].empty?
      result
    end

    # The AIML pattern matching is non-greedy
    def matcher_ending? path, matched
      return false if matched.count < 1
      next_word = path.is_a?(Array) ? path.first : path
      @children.has_key?(next_word) || GraphMark::ALL.include?(next_word) || MATCHERS.any? { |matcher| @children.has_key? matcher }
    end

    def rest_section_not_exists_in_tree? input_path
      clone_input_path = input_path.clone
      branch = clone_input_path.shift
      if not @children.has_key?(branch) and branch == GraphMark::THAT
        # the `topic` section is the last section
        branch = clone_input_path.shift until (branch.nil? or branch == GraphMark::TOPIC)
      end
      if not @children.has_key?(branch) and branch == GraphMark::TOPIC
        branch = clone_input_path.shift until branch.nil?
      end
      branch.nil? and clone_input_path.empty?
    end

    def skip_that_section branch, input_path
      clone_input_path = input_path.clone
      if branch == GraphMark::THAT
        # the `topic` section is the last section
        branch = clone_input_path.shift until (branch.nil? or clone_input_path.first == GraphMark::TOPIC)
      end
      {branch: branch, input_path: clone_input_path}
    end

    def current_section_finished? current_input_path
      current_input_path.empty? or GraphMark::ALL.include? current_input_path[1]
    end
  end
end
