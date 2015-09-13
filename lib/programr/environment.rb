module ProgramR
class Environment
  def initialize history
    @readonly_tags_file = "#{File.dirname(__FILE__)}/../../conf/readOnlyTags.yaml"
    @readonly_tags = YAML::load(File.open(@readonly_tags_file))
    @history = history
  end

  def get key
    return @history.send(key) if key =~ /that$/
    return questions.sample if key == 'question'
    return @readonly_tags[key] if @readonly_tags.key?(key)
    nil
  end

  def set key, value
    @history.topic = value if key == 'topic'
    @readonly_tags[key] = value
  end

  # not required method

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

  private

  def questions
    @readonly_tags['question']
  end
end
end
