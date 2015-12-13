# @title Custom Programr

## How to custom Environment and History

You can create a new class extended from {ProgramR::Environment} or {ProgramR::History}, and pass in {ProgramR::Facade}

```ruby
require 'programr'

class Environment < ProgramR::Environment
class History < ProgramR::History

robot = ProgramR::Facade.new Environment, History
```

## How to custom `<person>`, `<person2>`, `<gender>` output

You can modify {ProgramR::Person::Map}, {ProgramR::Person2::Map}, {ProgramR::Gender::Map}

```ruby
require 'programr'

person_map = {'male'  => {'我'     => '他',
                          '我的'   => '他的',
                          '我自己' => '他自己',
                          '他'     => '我',
                          '她'     => '我'},
             'female' => {'我'     => '她',
                          '我的'   => '她的',
                          '我自己' => '她自己',
                          '他'     => '我',
                          '她'     => '我'}}
ProgramR::Person::Map[/\b(我|我的|我自己|她|他)\b/i] = -> (match, environment) do
  gender = environment.get('gender')
  person_map[gender][match[1]]
end

robot = ProgramR::Facade.new
```
