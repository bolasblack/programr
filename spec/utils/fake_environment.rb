require 'singleton.new'

class FakeEnvironment
  include Singleton

  def initialize
    @stage = {}
  end

  def get key
    @stage[key]
  end

  def set key, value
    @stage[key] = value
  end
end
