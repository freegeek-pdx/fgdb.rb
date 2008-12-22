class SoapsAPI < SoapsBase
  def add_methods
    add_method("hi")
    add_method("fivetimes", "num")
  end

  def fivetimes(num)
    num * 5
  end

  def hi
    "hello"
  end
end
