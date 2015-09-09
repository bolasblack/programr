require 'programr/history'
require 'programr/environment'
require 'active_support/core_ext/string'

module ProgramR

class AimlTag
  @@environment = Environment.new

  def inspect
    inspect_str = respond_to?(:to_inspect, true) ? to_inspect : execute
    "<#{self.class.name.demodulize.tableize.singularize} -> #{inspect_str}>"
  end

  def to_s
    respond_to?(:execute) ? execute : super
  end

  def self.environment
    @@environment
  end

  def self.environment= env
    @@environment = env
  end

  private

  def to_response inputs = nil, need_puts = false
    return [''] if inputs.nil?
    inputs = [inputs].to_a unless inputs.is_a? Array
    result = inputs.map { |input| input.is_a?(Srai) ? input : input.to_s }
    puts result if need_puts
    result
  end
end

class Category < AimlTag
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

class Template < AimlTag
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
    @value.map(&:inspect)
  end
end

class Random < AimlTag
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
end

class Condition < AimlTag
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

  def condition_valid?
    if @property.nil?
      false
    elsif @@environment.get(@property).nil?
      @currentCondition.nil?
    elsif @@environment.get(@property) =~ /^#{@currentCondition}$/
      true
    else
      false
    end
  end

  private

  def to_inspect
    "#{@property}: #{@currentCondition} => #{text}"
  end

  def pick_condition attributes
    name = string_not_empty(attributes['name']) ? attributes['name'] : @property
    value = string_not_empty(attributes['value']) ? attributes['value'] : nil
    yield name, parse_value(value)
  end

  def string_not_empty string
    !(string.nil? or string.empty?)
  end

  def parse_value value
    value && value.sub('*', '.*')
  end

  def text
    texts = @conditions[@currentCondition]
    to_response (texts.nil? || texts.empty?) ? [''] : texts
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
    default_item_result || to_response
  end

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
    @property.nil? && @currentCondition.nil?
  end

  def execute
    if @conditionContainer.is_a?(Random) or default_item?
      text
    else
      super
    end
  end
end

class SetTag < AimlTag
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
    to_response value
  end

  private

  def to_inspect
    "#{@localname}: #{value}"
  end
end

class Input < AimlTag
  def initialize(someAttributes)
    @index = 1
    @index = someAttributes['index'].to_i if someAttributes.has_key?('index')
  end

  def execute
    to_response to_inspect
  end

  private

  def to_inspect
    History.instance.get_stimula @index
  end
end

class Star < AimlTag
  def initialize aStarName, someAttributes
    @star = aStarName
    @index = 0
    @index = someAttributes['index'].to_i - 1 unless someAttributes.empty?
  end

  def execute
    to_response get_star
  end

  private

  def get_star
    History.instance.send("get_#{@star}", @index)
  end

  def to_inspect
    "#{@star} #{@index} (#{get_star})"
  end
end

class GetTag < AimlTag
  def initialize aLocalname, someAttributes
    @localname = aLocalname.sub(/^get_/, '')
    if someAttributes.has_key?('index') && @localname == 'that'
      @localname = 'justbeforethat' if someAttributes['index'] == '2,1'
      someAttributes = {}
    end
    @attributed = someAttributes
  end

  def execute
    to_response @@environment.get(@attributed['name'] || @localname)
  end

  private

  def to_inspect
    "#{@localname}: #{execute}"
  end
end

class Think < AimlTag
  attr_reader :status

  def initialize aStatus
    @status = aStatus
  end

  def execute
    to_response @status
  end
end

class Size < AimlTag
  def execute
    to_response Category.cardinality.to_s
  end
end

class Sys_Date < AimlTag
  def execute
    to_response Date.today.to_s
  end
end

class Srai < AimlTag
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
  alias_method :to_inspect, :pattern
end

class Command < AimlTag
  def initialize text
    @command = text
  end

  def execute
    to_response `#{@command}`
  end
end

class ReplaceTag < AimlTag
  Map = {}

  def initialize
    @sentence = []
  end

  def add anObj
    @sentence.push anObj
  end

  def execute
    res = @sentence.map(&:to_s).join('').strip
    self.class::Map.each_pair do |matcher, fn|
      res = res.gsub(matcher) { |match| fn.call $~ }
    end
    res
  end
end

class Person < ReplaceTag
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

  Map = {
    /\b(she|he|i|me|my|myself|mine)\b/i => -> (match) do
      gender = @@environment.get('gender')
      @@swap[gender][match[1].downcase]
    end
  }
end

class Person2 < ReplaceTag
  @@swap = {'me' => 'you', 'you' => 'me'}

  Map = {
    /\b((with|to|of|for|give|gave|giving) (you|me)|you|i)\b/i => -> (match) do
      if match[3]
        match[2].downcase + ' '+ @@swap[match[3].downcase]
      elsif match[1].downcase == 'you'
        'i'
      elsif match[1].downcase == 'i'
        'you'
      end
    end
  }
end

class Gender < ReplaceTag
  Map = {
    /\b(she|he|him|his|(for|with|on|in|to) her|her)\b/i => -> (match) do
      case match[1].downcase
      when 'she' then 'he'
      when 'he' then 'she'
      when 'him', 'his' then 'her'
      when 'her' then 'his'
      else "#{match[2].downcase} him"
      end
    end
  }
end

end #ProgramR
