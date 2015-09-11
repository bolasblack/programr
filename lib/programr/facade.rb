require 'programr/graph_master'
require 'programr/environment'
require 'programr/aiml_parser'
require 'programr/history'
require 'programr/utils'

module ProgramR
  class Facade
    attr_reader :environment

    def initialize environment = Environment.new(History.instance)
      @environment  = environment
      @history      = History.instance
      @graph_master = GraphMaster.new
      @parser       = AimlParser.new @graph_master, @environment
    end

    def reset
      @graph_master.reset
    end

    def learn content
      if content.is_a? Array
        read_aiml(content) { |f| @parser.parse f }
      else
        @parser.parse content
      end
    end

    def loading(theCacheFilename='cache')
      cache = Cache::loading(theCacheFilename)
      @graph_master = cache if cache
    end

    def merging(theCacheFilename='cache')
      cache = Cache::loading(theCacheFilename)
      @graph_master.merge(cache) if cache
    end

    def dumping(theCacheFilename='cache')
      Cache::dumping(theCacheFilename, @graph_master)
    end

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
