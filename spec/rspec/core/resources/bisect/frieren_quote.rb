class FrierenQuote
  class << self
    def one
      @@one ||= "That is what hero Himmel would have done."
    end

    def change
      @@one = "The greatest enjoyment comes only during the pursuit of magic, you know."
    end
  end
end

