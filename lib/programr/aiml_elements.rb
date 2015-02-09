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

  def get_pattern
    res = ''
    @pattern.each { |tocken| res += tocken.to_s }
    res.split(/\s+/)
  end

  def get_that
    res = ''
    @that.each { |tocken| res += tocken.to_s }
    return res.split(/\s+/)
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
    @value.each{ |tocken| res += tocken.inspect }
    res
  end
end

class Random
  @@environment = Environment.new

  def initialize
    @conditions = []
  end

  def setListElement someAttributes
    @conditions.push([])
  end

  def add aBody
    @conditions[-1].push(aBody)
  end

  def execute
    res = ''
    @@environment.getRandom(@conditions).each do |tocken|
      res += tocken.to_s
    end
    res.strip
  end
  alias_method :to_s, :execute

  def inspect
    "random -> #{execute}"
  end
end

class Condition
  #se c'e' * nel value?
  @@environment = Environment.new

  def initialize someAttributes
    @conditions = {}
    @property = someAttributes['name']
    @currentCondition = someAttributes['value'].sub('*', '.*')
  end

  def add aBody
    unless @conditions[@currentCondition]
      @conditions[@currentCondition] = []
    end
    @conditions[@currentCondition].push(aBody)
  end

  def setListElement someAttributes
    @property = someAttributes['name'] if someAttributes.has_key?('name')
    @currentCondition = '_default'
    if(someAttributes.key?('value'))
      @currentCondition = someAttributes['value'].sub('*', '.*')
    end
  end

  def execute
    return '' unless(@@environment.get(@property) =~ /^#{@currentCondition}$/)
    res = ''
    @conditions[@currentCondition].each{|tocken|
      res += tocken.to_s
    }
    return res.strip
  end
  alias_method :to_s, :execute

  def inspect
    "condition -> #{execute}"
  end
end

class ListCondition < Condition
  def initialize someAttributes
    @conditions = {}
    @property = someAttributes['name'] if someAttributes.has_key? 'name'
  end

  def execute
    @conditions.keys.each do |key|
      if(@@environment.get(@property) == key)
        res = ''
        @conditions[key].each{|tocken|
        res += tocken.to_s
      }
      return res.strip
      end
    end
    return ''
  end
  alias_method :to_s, :execute
end

class SetTag
  @@environment = Environment.new

  def initialize aLocalname, attributes
    if attributes.empty?
      @localname = aLocalname.sub(/^set_/, '')
    else
      @localname = attributes['name']
    end
    @value = []
  end

  def add aBody
    @value.push(aBody)
  end

  def execute
    res = ''
    @value.each { |tocken| res += tocken.to_s }
    @@environment.set(@localname, res.strip)
  end
  alias_method :to_s, :execute

  def inspect
    "set tag #{@localname} -> #{execute}"
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
    @sentence.each { |tocken| res += tocken.to_s }
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
    @sentence.each { |tocken| res += tocken.to_s }
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
    @sentence.each { |tocken| res += tocken.to_s }
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
