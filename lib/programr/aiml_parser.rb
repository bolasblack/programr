# Listen block arguments document:
#   http://ruby-doc.org/stdlib-2.0.0/libdoc/rexml/rdoc/REXML/SAX2Listener.html
require 'rexml/parsers/sax2parser'
require 'programr/aiml_elements'

# gli accenti nel file di input vengono trasformati in &apos; !!!
#
module  ProgramR
class AimlParser
  def initialize(learner); @learner = learner end

  def parse(aiml)
    @parser = REXML::Parsers::SAX2Parser.new(aiml)
    category             = nil
    openLabels           = []
    patternIsOpen        = false
    thatIsOpen           = false
    currentSetLabel      = nil
    currentCondition     = nil
    currentConditionItem = nil
    currentSrai          = nil
    currentGender        = nil
    currentPerson        = nil
    currentPerson2       = nil
    currentTopic         = nil

    @parser.listen(%w{ category }) do |uri, localname, qname, attributes|
      category = Category.new
      category.topic = currentTopic if currentTopic
    end

    @parser.listen(:end_element, %w{ category }) { @learner.learn(category) }

    @parser.listen(%w{ topicstar thatstar star }) do |uri, localname, qname, attributes|
      openLabels[-1].add(Star.new(localname, attributes))
    end

### condition -- condition
    @parser.listen(%w{ condition }) do |uri, localname, qname, attributes|
      if attributes.has_key?('value')
        currentCondition = Condition.new(attributes)
      else
        currentCondition = ListCondition.new(attributes)
      end
      openLabels[-1].add(currentCondition)
      openLabels.push(currentCondition)
    end

    @parser.listen(%w{ random }) do |uri, localname, qname, attributes|
      currentCondition = Random.new
      openLabels[-1].add(currentCondition)
      openLabels.push(currentCondition)
    end

    @parser.listen(:characters, %w{ condition }) do |text|
      next if text =~ /^\s+$/
      currentCondition.add(text)
    end

    @parser.listen(:end_element, %w{ condition random }) do
      currentCondition = nil
      openLabels.pop
    end

    @parser.listen(%w{ li }) do |uri, localname, qname, attributes|
      next unless currentCondition
      currentConditionItem = ConditionItem.new attributes, currentCondition
      currentCondition.setListElement(currentConditionItem)
      openLabels.push currentConditionItem
    end

    @parser.listen(:characters, %w{ li }) do |text|
      next unless currentConditionItem
      next if text =~ /^\s+$/
      currentConditionItem.add text
    end

    @parser.listen(:end_element, %w{ li }) do
      next unless currentConditionItem
      currentConditionItem = nil
      openLabels.pop
    end
### end condition -- condition

    @parser.listen([/^get.*/, /^bot_*/, 'for_fun', /that$/, 'question']) do
                   |uri, localname, qname, attributes|
      unless openLabels.empty?
        openLabels[-1].add(ReadOnlyTag.new(localname, attributes))
      end
    end

    @parser.listen(%w{ bot name }) do |uri, localname, qname, attributes|
      if localname == 'bot'
        localname = 'bot_' + attributes['name']
      else
        localname = 'bot_name'
      end

      if patternIsOpen
        category.add_pattern(ReadOnlyTag.new(localname, {}))
      elsif thatIsOpen
        category.add_that(ReadOnlyTag.new(localname, {}))
      else
        openLabels[-1].add(ReadOnlyTag.new(localname, {}))
      end
    end

### set
    @parser.listen([/^set_*/, 'set']) do |uri, localname, qname, attributes|
      setObj = SetTag.new(localname, attributes)
      openLabels[-1].add(setObj)
      openLabels.push(setObj)
    end

    @parser.listen(:characters, [/^set_*/]) do |text|
      openLabels[-1].add(text)
    end

    @parser.listen(:end_element, [/^set_*/, 'set']) do
      openLabels.pop
    end
### end set

### pattern
    @parser.listen(%w{ pattern }){ patternIsOpen = true }
    @parser.listen(:characters, %w{ pattern }) do |text|
      #TODO verify if case insensitive. Cross check with facade
      category.add_pattern(text.upcase)
    end
    @parser.listen(:end_element, %w{ pattern }){ patternIsOpen = false }
#end pattern

#### that
    @parser.listen(%w{ that }){ thatIsOpen = true }
    @parser.listen(:characters, %w{ that }){ |text| category.add_that(text) }
    @parser.listen(:end_element, %w{ that }){ thatIsOpen = false }
### end that

### template
    @parser.listen(%w{ template }) do
      category.template = Template.new
      openLabels.push(category.template)
    end

    @parser.listen(:characters, %w{ template }) do |text|
      category.template.append(text)
    end

    @parser.listen(:end_element, %w{ template }) do
      openLabels.pop
    end
### end template

    @parser.listen(%w{ input }) do |uri, localname, qname, attributes|
      category.template.add(Input.new(attributes))
    end

### think
    @parser.listen(:start_element, %w{ think }) do
      openLabels[-1].add(Think.new('start'))
    end

    @parser.listen(:end_element, %w{ think }) do
      openLabels[-1].add(Think.new('end'))
    end
###end think

    @parser.listen(:characters, %w{ uppercase }) do |text|
      openLabels[-1].add(text.upcase.gsub(/\s+/, ' '))
    end

    @parser.listen(:characters, %w{ lowercase }) do |text|
      openLabels[-1].add(text.downcase.gsub(/\s+/, ' '))
    end

    @parser.listen(:characters, %w{ formal }) do |text|
      text.gsub!(/(\w+)/){ $1.capitalize }
      openLabels[-1].add(text.gsub(/\s+/, ' '))
    end

    @parser.listen(:characters, %w{ sentence }) do |text|
      openLabels[-1].add(text.capitalize.gsub(/\s+/, ' '))
    end

    @parser.listen(%w{ date }) do
      openLabels[-1].add(Sys_Date.new)
    end

    @parser.listen(:characters, %w{ system }) do |text|
      openLabels[-1].add(Command.new(text))
    end

    @parser.listen(%w{ size }) do
      openLabels[-1].add(Size.new)
    end

### srai
    @parser.listen(%w{ sr }) do |uri, localname, qname, attributes|
      openLabels[-1].add(Srai.new(Star.new('star', {})))
    end

    @parser.listen(%w{ srai }) do |uri, localname, qname, attributes|
      currentSrai = Srai.new
      openLabels[-1].add(currentSrai)
      openLabels.push(currentSrai)
    end

    @parser.listen(:characters, %w{ srai }) do |text|
      currentSrai.add(text)
    end

    @parser.listen(:end_element, %w{ srai }) do
      currentSrai = nil
      openLabels.pop
    end
### end srai

### gender
    @parser.listen(%w{ gender }) do |uri, localname, qname, attributes|
      currentGender = Gender.new
      openLabels[-1].add(currentGender)
      openLabels.push(currentGender)
    end

    @parser.listen(:characters, %w{ gender }) do |text|
      currentGender.add(text)
    end

    @parser.listen(:end_element, %w{ gender }) do
      currentGender = nil
      openLabels.pop
    end
### end gender

### person
    @parser.listen(%w{ person }) do |uri, localname, qname, attributes|
      currentPerson = Person.new
      openLabels[-1].add(currentPerson)
      openLabels.push(currentPerson)
    end

    @parser.listen(:characters, %w{ person }) do |text|
      currentPerson.add(text)
    end

    @parser.listen(:end_element, %w{ person }) do
      currentPerson = nil
      openLabels.pop
    end
### end person

### person2
    @parser.listen(%w{ person2 }) do |uri, localname, qname, attributes|
      currentPerson2 = Person2.new
      openLabels[-1].add(currentPerson2)
      openLabels.push(currentPerson2)
    end

    @parser.listen(:characters, %w{ person2 }) do |text|
      currentPerson2.add(text)
    end

    @parser.listen(:end_element, %w{ person2 }) do
      currentPerson2 = nil
      openLabels.pop
    end
### end perso2

### topic
    @parser.listen(%w{ topic }) do |uri, localname, qname, attributes|
      currentTopic = attributes['name']
    end

    @parser.listen(:end_element, %w{ topic }) do
      currentTopic = nil
    end
### end topic

    @parser.parse
  end
end #Aiml@parser
end
