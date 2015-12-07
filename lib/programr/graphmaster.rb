module ProgramR
  class Graphmaster
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
      path += [GraphMark::THAT] + category.thats unless category.thats.empty?
      path += [GraphMark::TOPIC] + category.topics unless category.topics.empty?
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

      path = "#{segmented_reaction.join ' '} #{GraphMark::THAT} #{last_said} #{GraphMark::TOPIC} #{cur_topic}".split(/\s+/)
      template = @graph.get_template(path, starGreedy)
      template ? template.value : []
    end

    def reset
      @graph = GraphNode.new
    end

    def to_s
      @graph.inspect_node
    end

    def register_segmenter lang, &block
      if block_given?
        @segmenter_map[lang] = block
      end
    end
  end
end
