require 'programr/environment'

module ProgramR

class Category
  attr_accessor :template, :that, :topic

  @@cardinality = 0

  def self.cardinality
    @@cardinality
  end

  def initialize
    @@cardinality += 1
    @pattern = []
    @that    = []
  end

  def add_pattern anObj
    @pattern.push anObj
  end

  def add_that anObj
    @that.push anObj
  end

  def patterns
    @pattern.map(&:to_s).join('').split(/\s+/)
  end

  def thats
    @that.map(&:to_s).join('').split(/\s+/)
  end

  def topics
    return [] if @topic.nil?
    @topic.split(/\s+/)
  end
end

class Template
  attr_accessor :value

  def initialize
    @value = []
  end

  def add anObj
    @value << anObj
  end

  def append aString
    @value << aString.gsub(/\s+/, ' ')
  end

  def inspect
    res = ''
    @value.each{ |token| res += token.inspect }
    res
  end
end

class Random
  @@environment = Environment.new

  def initialize
    @condition_items = []
  end

  def setListElement condition_item
    @condition_items << condition_item
  end

  def add aBody
    @condition_items[-1].add(aBody)
  end

  def execute
    @condition_items.sample.execute
  end
  alias_method :to_s, :execute

  def inspect
    "random -> #{execute}"
  end
end

class Condition
  @@environment = Environment.new

  def initialize someAttributes
    @conditions = {}
    pick_condition someAttributes do |name, value|
      @property = name
      @currentCondition = value
    end
  end

  def add aBody
    unless @conditions[@currentCondition]
      @conditions[@currentCondition] = []
    end
    @conditions[@currentCondition].push(aBody)
  end

  def setListElement someAttributes
    pick_condition someAttributes do |name, value|
      @property = name
      @currentCondition = value
    end
  end

  def execute
    condition_valid? ? text : ''
  end
  alias_method :to_s, :execute

  def inspect
    "condition -> #{execute}"
  end

  def condition_valid?
    return false if @property.nil?
    if @@environment.get(@property).nil? && @currentCondition == '_default'
      true
    elsif @@environment.get(@property) =~ /^#{@currentCondition}$/
      true
    else
      false
    end
  end

  private

  def pick_condition attributes
    name = string_not_empty(attributes['name']) ? attributes['name'] : @property
    value = string_not_empty(attributes['value']) ? attributes['value'] : '_default'
    yield name, parse_value(value)
  end

  def string_not_empty string
    !(string.nil? or string.empty?)
  end

  def parse_value value
    value.sub '*', '.*'
  end

  def text
    texts = @conditions[@currentCondition]
    (texts.nil? || texts.empty?) ? '' : texts.map(&:to_s).join('').strip
  end
end

class ListCondition < Condition
  attr_reader :property

  def initialize someAttributes
    @condition_items = []
    @property = someAttributes['name'] if someAttributes.has_key? 'name'
  end

  def add text
    @condition_items[-1].add text
  end

  def setListElement condition_item
    @condition_items << condition_item
  end

  def execute
    @condition_items.each do |item|
      return item.execute if item.condition_valid?
    end
    default_item_result || ''
  end
  alias_method :to_s, :execute

  private

  def default_item_result
    get_default_item = -> do
      @condition_items.each { |item| return item if item.default_item? }
    end
    item = get_default_item.call
    item.is_a?(Array) ? nil : item.execute
  end
end

class ConditionItem < Condition
  def initialize someAttributes, conditionContainer
    @conditionContainer = conditionContainer
    @conditions = {}
    if @conditionContainer.is_a? ListCondition
      pick_condition someAttributes do |name, value|
        @property = name || @conditionContainer.property
        @currentCondition = value
      end
    end
  end

  def default_item?
    @property.nil? && @currentCondition == '_default'
  end

  def execute
    if @conditionContainer.is_a?(Random) or default_item?
      text
    else
      super
    end
  end

  def inspect
    "condition item -> #{execute}"
  end
end

class SetTag
  @@environment = Environment.new

  def initialize aLocalname, attributes
    if attributes['name'].nil?
      @localname = aLocalname.sub(/^set_/, '')
    else
      @localname = attributes['name']
    end
    @value = []
  end

  def add aBody
    @value.push(aBody)
  end

  def value
    @value.map(&:to_s).join('').strip
  end

  def execute
    @@environment.set(@localname, value)
  end
  alias_method :to_s, :execute

  def inspect
    "set tag #{@localname} -> #{value}"
  end
end

class Input
  @@environment = Environment.new

  def initialize(someAttributes)
    @index = 1
    @index = someAttributes['index'].to_i if someAttributes.has_key?('index')
  end

  def execute
    @@environment.getStimula(@index)
  end
  alias_method :to_s, :execute

  def inspect
    "input -> #{@@environment.getStimula(@index)}"
  end
end

class Star
  @@environment = Environment.new

  def initialize aStarName, someAttributes
    @star = aStarName
    @index = 0
    @index = someAttributes['index'].to_i - 1 unless someAttributes.empty?
  end

  def execute
    @@environment.send(@star, @index)
  end
  alias_method :to_s, :execute

  def inspect
    "#{@star} #{@index} -> #{@@environment.send(@star, @index)}"
  end
end

class ReadOnlyTag
  @@environment = Environment.new

  def initialize aLocalname, someAttributes
    @localname = aLocalname.sub(/^get_/, '')
    if someAttributes.has_key?('index') && @localname == 'that'
      @localname = 'justbeforethat' if someAttributes['index'] == '2,1'
      someAttributes = {}
    end
    @attributed = someAttributes
  end

  def execute
    return @@environment.get(@localname) if @attributed.empty?
    @@environment.get(@attributed['name'])
  end
  alias_method :to_s, :execute

  def inspect
    "ReadOnlyTag #{@localname} -> #{execute}"
  end
end

class Think
  def initialize aStatus
    @status = aStatus
  end

  def execute
    @status
  end
  alias_method :to_s, :execute

  def inspect
    "think status -> #{@status}"
  end
end

class Size
  def execute
    Category.cardinality.to_s
  end
  alias_method :to_s, :execute

  def inspect
    "size -> #{execute}"
  end
end

class Sys_Date
  def execute
    Date.today.to_s
  end
  alias_method :to_s, :execute

  def inspect
    "date -> #{execute}"
  end
end

class Srai
  def initialize anObj = nil
    @pattern = []
    add(anObj) if anObj
  end

  def add anObj
    @pattern.push anObj
  end

  def pattern
    @pattern.map(&:to_s).join('').strip
  end

  def inspect
    "srai -> #{pattern}"
  end
end

class Person2
  @@environment = Environment.new
  @@swap = {'me' => 'you', 'you' => 'me'}

  def initialize
    @sentence = []
  end

  def add anObj
    @sentence.push anObj
  end

  def execute
    res = ''
    @sentence.each { |token| res += token.to_s }
    gender = @@environment.get('gender')
    res.gsub(/\b((with|to|of|for|give|gave|giving) (you|me)|you|i)\b/i) do
      if $3
        $2.downcase+' '+@@swap[$3.downcase]
      elsif $1.downcase == 'you'
        'i'
      elsif $1.downcase == 'i'
        'you'
      end
    end
  end
  alias_method :to_s, :execute

  def inspect
    "person2 -> #{execute}"
  end
end

class Person
  @@environment = Environment.new
  @@swap = {'male' => {'me'     => 'him',
                       'my'     => 'his',
                       'myself' => 'himself',
                       'mine'   => 'his',
                       'i'      => 'he',
                       'he'     => 'i',
                       'she'    => 'i'},
            'female' => {'me'   => 'her',
                         'my'     => 'her',
                         'myself' => 'herself',
	                       'mine'   => 'hers',
                         'i'      => 'she',
                         'he'     => 'i',
                         'she'    => 'i'}}

  def initialize
    @sentence = []
  end

  def add anObj
    @sentence.push anObj
  end

  def execute
    res = ''
    @sentence.each { |token| res += token.to_s }
    gender = @@environment.get('gender')
    res.gsub(/\b(she|he|i|me|my|myself|mine)\b/i) do
      @@swap[gender][$1.downcase]
    end
  end
  alias_method :to_s, :execute

  def inspect
    "person-> #{execute}"
  end
end

class Gender
  def initialize
    @sentence = []
  end

  def add anObj
    @sentence.push anObj
  end

  def execute
    res = ''
    @sentence.each { |token| res += token.to_s }
    res.gsub(/\b(she|he|him|his|(for|with|on|in|to) her|her)\b/i) do
      pronoun = $1.downcase
      if pronoun == 'she'
        'he'
      elsif pronoun ==  'he'
        'she'
      elsif pronoun ==  'him' || pronoun ==  'his'
        'her'
      elsif pronoun ==  'her'
        'his'
      else
        $2.downcase + ' ' + 'him'
      end
    end
  end
  alias_method :to_s, :execute

  def inspect
    "gender -> #{execute}"
  end
end

class Command
  def initialize text
    @command = text
  end

  def execute
    `#{@command}`
  end
  alias_method :to_s, :execute

  def inspect
    "cmd -> #{@command}"
  end
end

end #ProgramR
