module LibraryModelHelper
  def blah(one, two)
    self.[](one,two)
  end

  def author
    blah(100, 'a')
  end

  def title
    blah(245, 'a')
  end

  def description
    blah(520, 'a')
  end

  def isbn
    blah(20, 'a')
  end
end
