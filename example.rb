# coding: utf-8
require 'bundler'
Bundler.setup :default

require 'programr'

robot = ProgramR::Facade.new

# You can custom readonly tags
robot.environment.readonly_tags_file = 'spec/data/readOnlyTags.yaml'

robot.learn ['spec/data']
robot.learn <<-AIML
  <category>
    <pattern>Hello</pattern>
    <template>World</template>
  </category>
AIML

while true
  print '>> '
  s = STDIN.gets.chomp
  reaction = robot.get_reaction(s)
  STDOUT.puts "<< #{reaction}"
end
