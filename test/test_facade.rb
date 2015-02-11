require_relative 'helper'

require 'test/unit'
require 'programr/facade'

class TestFacade < Test::Unit::TestCase
  def setup
    @robot = ProgramR::Facade.new
  end

  def test_learn_directly
    require 'securerandom'
    pattern = SecureRandom.hex
    result = SecureRandom.hex

    @robot.learn <<-AIML
<category>
  <pattern>#{pattern}</pattern>
  <template>#{result}</template>
</category>
    AIML

    assert_equal result, @robot.get_reaction(pattern)
  end

  def test_learn_folder
    @robot.learn ['test']
    assert_equal 'test succeeded', @robot.get_reaction('atomic test')
  end
end
