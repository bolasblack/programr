module ProgramR
  THAT  = '<that>'
  TOPIC = '<topic>'

  class GraphMaster
    attr_reader :graph

    def initialize
      @segmenter_map = {}
      reset
    end

    def learn category
      segmenter = @segmenter_map[category.language]
      if category.language.nil? or segmenter.nil?
        path = category.patterns
      else
        path = segmenter.call category.patterns
      end
      path += [THAT] + category.thats unless category.thats.empty?
      path += [TOPIC] + category.topics unless category.topics.empty?
      @graph.learn(category, path)
    end

    def get_reaction stimula, last_said, cur_topic, starGreedy
      if @segmenter_map.empty?
        segmented_reaction = [stimula]
      else
        segmented_reaction = @segmenter_map.reduce [stimula] do |last_state, kvmap|
          kvmap.last.call last_state
        end
      end

      path = "#{segmented_reaction.join ' '} #{THAT} #{last_said} #{TOPIC} #{cur_topic}".split(/\s+/)
      template = @graph.get_template(path, starGreedy)
      template ? template.value : []
    end

    def reset
      @graph = Node.new
    end

    def to_s
      @graph.inspectNode
    end

    def register_segmenter lang, &block
      if block_given?
        @segmenter_map[lang] = block
      end
    end
  end

  class Node
    attr_reader :children

    def initialize
      @template = nil
      @children = {}
    end

    def learn category, path
      branch = path.shift
      # Only the tail node has @template
      return @template = category.template unless branch
      @children[branch] = Node.new unless @children[branch]
      @children[branch].learn(category, path)
    end

    # the function will only return nil or @template if graph ending,
    # otherwise it will only return currentTemplate
    #
    # handle case: 'abcdefgh'
    #   [a b c d e f g h]
    #   [a *]
    #   [a * h]
    #   [a * * h]
    #   [a _ *]
    #   [a _ * h]
    #   [a _ _ * h]
    #   [a _ * * h]
    def get_template pattern, starGreedy, isGreedy = false
      currentTemplate = nil
      gotValue        = nil
      curGreedy       = []

      # if current node is the tail node
      if @template
        if isGreedy
	        starGreedy.push(pattern.shift) until pattern.empty? || prev_section_finished?(pattern)
        end
        return @template if pattern.empty?
        currentTemplate = @template if exist_next_section? pattern
      end

      branch = pattern.shift
      isGreedy = false if head_of_next_section? branch
      branch = skip_that_section_if_need branch, pattern
      return if branch.nil?

      if @children[branch]
        # normal case 'abc|defgh' -> [a b c d e f g h]
        # build a recursion if a branch matched
        gotValue = @children[branch].get_template pattern.clone, curGreedy
      elsif isGreedy
        # greedy case 'abc|defgh' -> [a * * h]
        # or stash word for greedy, then retry
        curGreedy.push branch
        gotValue = get_template pattern.clone, curGreedy, true
      end

      if gotValue
        starGreedy.push(branch) if head_of_next_section? branch
        starGreedy.concat(curGreedy)
        return gotValue
      end

      return currentTemplate if currentTemplate

      %w{_ *}.each do |star|
        next unless @children.has_key? star
        # 'ab|cdefgh' -> [a * h]
        next unless gotValue = @children[star].get_template(pattern.clone, curGreedy, true)
        starGreedy.push(branch) if prev_section_finished? branch
        starGreedy.concat(['<newMatch>', branch].concat(curGreedy))
        return gotValue
      end

      nil
    end

    def inspectNode nodeId = nil, ind = 0
      str = ''
      str += '| ' * (ind - 1) + "|_#{nodeId}" unless ind == 0
      str += ": [#{@template.inspect}]" if @template
      str += "\n" unless ind == 0
      @children.each_key{ |c| str += @children[c].inspectNode(c, ind + 1) }
      str
    end

    private

    def prev_section_finished? path
      factor = path.is_a?(Array) ? path.first : path
      factor == THAT || factor == TOPIC
    end
    alias_method :exist_next_section?, :prev_section_finished?
    alias_method :head_of_next_section?, :prev_section_finished?

    def skip_that_section_if_need branch, pattern
      # skip `that` if there is no any `that` branch in children
      # the `topic` section is the last section, so we needn't skip it
      if branch == THAT and not @children.has_key?(THAT)
        branch = pattern.shift until (branch.nil? or branch == TOPIC)
      end
      branch
    end
  end

end #ProgramR
