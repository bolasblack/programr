class FakeGraphmaster
  attr_reader :learned

  def initialize
    @learned = []
  end

  def learn category
    @learned << category
  end
end
