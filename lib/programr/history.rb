module ProgramR
  class History
    attr_accessor :topic

    def initialize
      @topic       = 'undef'
      @inputs      = []
      @responses   = []
      @star_greedy  = []
      @that_greedy  = []
      @topic_greedy = []
    end


    # @param index [Numeric] get stimula, 0 is the nearest one
    # @return [String, nil]
    def get_stimula index
      @inputs[index]
    end

    # @param stimula [String]
    def update_stimula stimula
      @inputs.unshift stimula
    end


    # @param index [Numeric] get response, 0 is the nearest one
    # @return [String, nil]
    def get_response index
      @responses[index]
    end

    # @param response [String]
    def update_response response
      @responses.unshift response
    end


    # @return [String] return last response or 'undef'
    def that
      return 'undef' unless @responses[0]
      @responses[0]
    end

    # @return [String] return last second response or 'undef'
    def justbeforethat
      return 'undef' unless @responses[1]
      @responses[1]
    end

    # @return [String] return last input or 'undef'
    def justthat
      return 'undef' unless @inputs[0]
      @inputs[0]
    end

    # @return [String] return last second input or 'undef'
    def beforethat
      return 'undef' unless @inputs[1]
      @inputs[1]
    end


    # @param index [Numeric] get star, 0 is the nearest one
    # @return [String]
    def get_star index
      return 'undef' unless @star_greedy[index]
      @star_greedy[index].join(' ')
    end

    # @param index [Numeric] get thatstar, 0 is the nearest one
    # @return [String]
    def get_thatstar index
      return 'undef' unless @that_greedy[index]
      @that_greedy[index].join(' ')
    end

    # @param index [Numeric] get topicstar, 0 is the nearest one
    # @return [String]
    def get_topicstar index
      return 'undef' unless @topic_greedy[index]
      @topic_greedy[index].join(' ')
    end

    # @param star_greedy_array [Array<String>]
    def update_star_matches star_greedy_array
      @star_greedy = []
      @that_greedy = []
      @topic_greedy = []
      current_greedy = @star_greedy
      star_greedy_array.each do |greedy|
        if greedy == GraphMark::THAT
          current_greedy = @that_greedy
        elsif greedy == GraphMark::TOPIC
          current_greedy = @topic_greedy
        elsif greedy == '<star>'
          current_greedy.push([])
        else
          current_greedy.last.push(greedy)
        end
      end
    end
  end
end
