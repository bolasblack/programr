require 'yaml'
require 'singleton.new'
require 'programr/history'

module ProgramR
class Environment
  include Singleton

  def initialize
    @readonly_tags_file = "#{File.dirname(__FILE__)}/../../conf/readOnlyTags.yaml"
    @readonly_tags = YAML::load(File.open(@readonly_tags_file))
    @history = History.instance
    srand(1)
  end

  def readonly_tags_file
    @readonly_tags_file
  end

  def readonly_tags_file= file
    unless File.exist? file
      raise "File #{file} not exist"
    end
    @readonly_tags_file = file
    @readonly_tags = YAML::load(File.open(file))
  end

  def get(aTag)
    send(aTag)
  end

  def set aTag, aValue
    @history.updateTopic(aValue) if aTag == 'topic'
    @readonly_tags[aTag] = aValue
  end

  def method_missing(methId)
    tag = methId.id2name
    return @history.send(tag) if(tag =~ /that$/)
    return @readonly_tags[tag] if(@readonly_tags.key?(tag))
    nil
  end

  def test
    #should overwrite test ....
    return @readonly_tags[tag] if(@readonly_tags.key?(tag))
    ''
  end

  def star(anIndex)
    @history.getStar(anIndex)
  end

  def thatstar(anIndex)
    @history.getThatStar(anIndex)
  end

  def topicstar(anIndex)
    @history.getTopicStar(anIndex)
  end

  def male
    @readonly_tags['gender'] = 'male'
    return 'male'
  end

  def female
    @readonly_tags['gender'] = 'female'
    return 'female'
  end

  def question
    @readonly_tags['question'][rand(@readonly_tags['question'].length-1)]
  end

  def getStimula(anIndex)
    @history.getStimula(anIndex)
  end
end
end
