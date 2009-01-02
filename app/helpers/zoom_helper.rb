module ZoomHelper
  class Marc
    include LibraryModelHelper

    def [](a,b)
      # magic
    end
  end

  def lookup_loc(isbns)
    # finds the first matching in the isbns array, if it's an array
    # returns a Marc object, or nil
  end

  def list_alternatives(isbn)
    # returns an array of alternatives including isbn
  end
end
