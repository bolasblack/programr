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

  def get key
    send key
  end

  def set key, value
    @history.topic = value if key == 'topic'
    @readonly_tags[key] = value
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

  def star index
    @history.get_star index
  end

  def thatstar index
    @history.get_that_star index
  end

  def topicstar index
    @history.get_topic_star index
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

  def get_stimula index
    @history.get_stimula index
  end
end
end
