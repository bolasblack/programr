class FakeEnvironment
  def initialize history = nil
    @stage = {}
    @history = history
  end

  def get key
    @stage[key]
  end

  def set key, value
    @stage[key] = value
  end
end
