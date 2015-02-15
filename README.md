# ProgramR

## About

This is a fork of http://aiml-programr.rubyforge.org/ (authored in 2007) from [robertjwhitney/programr](https://github.com/robertjwhitney/programr).

ProgramR is a Ruby implementation of an interpreter for the Artificial Intelligence Markup Language (AIML) based on the work of Dr. Wallace and defined by the Alicebot and AIML Architecture Committee of the A.L.I.C.E. AI Foundation http://alicebot.org

Some of the ALICE AIML files have thrown parse errors with certain caraters in [@robertjwhitney](https://github.com/robertjwhitney)'s tests, so a subset is available here: https://github.com/robertjwhitney/alice-programr

**Original Authors**: Mauro Cicio, Nicholas H.Tollervey and Ben Minton


## Installation

Add this line to your application's Gemfile:

    gem 'programr', github: 'bolasblack/programr', branch: 'master'

And then execute:

    $ bundle

You can find a set of ALICE AIML files hosted at http://code.google.com/p/aiml-en-us-foundation-alice

## Usage

```ruby
#programr_test.rb

require 'bundler'
Bundler.setup :default

require 'programr'

# You can custom readonly tags
ProgramR::Environment.readonly_tags_file = 'test/data/readOnlyTags.yaml'

robot = ProgramR::Facade.new

# pass in a folder array or plain aiml content
robot.learn ['spec/data']
robot.learn <<-AIML
  <category>
    <pattern>#{pattern}</pattern>
    <template>#{result}</template>
  </category>
AIML

while true
  print '>> '
  s = STDIN.gets.chomp
  reaction = robot.get_reaction(s)
  STDOUT.puts "<< #{reaction}"
end
```

## Todo

* Support `<srai>` in `<person>`, `<person2>` and `<set_*>`
* `<person>`, `<person2>`, `<gender>` can support simple i18n
* Support chinese
* Support [AIML 2.0 Draft](https://docs.google.com/document/d/1wNT25hJRyupcG51aO89UcQEiG-HkXRXusukADpFnDs4/pub)
* Clean test

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
