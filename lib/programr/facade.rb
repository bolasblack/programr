module ProgramR
  class Facade
    attr_reader :environment, :history

    # Create a new robot
    #
    # @param custom_environment the custom {Environment} class
    # @param custom_history the custom {History} class
    def initialize custom_environment = Environment, custom_history = History
      @history      = custom_history.new
      @environment  = custom_environment.new @history
      @graph_master = GraphMaster.new
      @parser       = AimlParser.new @graph_master, @environment, @history
    end

    # Learn knowledges
    #
    # @param content [String, Array<String>] folder array of aiml files or plain aiml content
    def learn content
      if content.is_a? Array
        read_aiml(content) { |f| @parser.parse f }
      else
        @parser.parse content
      end
    end

    # Talk with robot
    #
    # @!method get_reaction(stimula)
    # @param stimula [String] the message speak to robot
    # @return [String] the message robot said
    def get_reaction(stimula, firstStimula = true)
      starGreedy = []
      #TODO verify if case insensitive. Cross check with parser
      @history.update_stimula(stimula.upcase) if firstStimula
      reaction = @graph_master.get_reaction stimula.upcase, @history.that, @history.topic, starGreedy
      #puts reaction.inspect
      @history.update_star_matches starGreedy
      res = evaluate(reaction, starGreedy).flatten.reduce([]) do |memo, part|
        # clean case [" ", "part 1 ", " ", "part 2", " "]
        if !memo.last || !memo.last.end_with?(' ')
          memo << part
        elsif part && memo.last.end_with?(' ') && !part.strip.empty?
          memo << part
        end
        memo
      end.join('').strip
      #TODO verify if case insensitive. Cross check with main program & parser
      @history.update_response(res.upcase) if firstStimula
      res
    end

    # Register segmenter for specified language
    #
    # @param lang [Symbol] the language tag segmenter for
    # @param block [Block] the segmenter
    # @note
    #   Graphmaster decide which segmenters process aiml partten by read
    #   `language` attribute of `Category` tag.
    #
    #   But it will not detect which language of user stimula, Graphmaster
    #   will pass stimula to all segmenter, block should decide what to do
    #   by it self.
    def register_segmenter lang, &block
      @graph_master.register_segmenter lang, &block
    end

    # Reset Graphmaster
    def reset
      @graph_master.reset
    end

    def to_s
      @graph_master.to_s
    end

    private

    def evaluate reaction, starGreedy
      thinkIsActive = false
      reaction.map do |token|
        if token.is_a? Srai
          token = get_reaction token.pattern, false
          @history.update_star_matches starGreedy
        end
        if token.is_a? Think
          thinkIsActive = !thinkIsActive
          next
        end

        responses = token.is_a?(String) ? token : token.execute
        if thinkIsActive
          ''
        elsif responses.is_a? Array
          evaluate responses, starGreedy
        else
          responses
        end
      end
    end

    def read_aiml files_and_dirs, &block
      files_and_dirs.map do |file|
        if File.file?(file) && File.fnmatch?('*.aiml', file)
          File.open(file, 'r') { |content| block.call content }
        else
          read_aiml Dir["#{file}/*"], &block
        end
      end
    end
  end
end
