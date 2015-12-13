# @title Custom Programr

## How to custom Environment and History

You can create a new class extended from {ProgramR::Environment} or {ProgramR::History}, and pass in {ProgramR::Facade}

```ruby
require 'programr'

class Environment < ProgramR::Environment
class History < ProgramR::History

robot = ProgramR::Facade.new Environment, History
```

## How to custom word segmentation algorithm

```ruby
require 'programr'

robot = ProgramR::Facade.new

def is_has_chinese str
  str =~ /\p{Han}/
end
robot.register_segmenter(:zh) do |segments|
  segments.map do |segment|
    next segment unless is_has_chinese segment
    parts = segment.split(' ')
    parts.map do |part|
      next part unless is_has_chinese part
      part.split ''
    end
  end.flatten
end
```

## How to custom `<person>`, `<person2>`, `<gender>` output

You can modify {ProgramR::Person::Map}, {ProgramR::Person2::Map}, {ProgramR::Gender::Map}

```ruby
require 'programr'

person_map = {'male'  => {'我'     => '他',
                          '他'     => '我',
                          '她'     => '我'},
             'female' => {'我'     => '她',
                          '他'     => '我',
                          '她'     => '我'}}
ProgramR::Person::Map[/\b(我|我的|我自己|她|他)\b/i] = -> (match, environment) do
  gender = environment.get('gender')
  person_map[gender][match[1]]
end

robot = ProgramR::Facade.new
```
