module DataSeeding
  module Commands
    def rollback
      throw(:rollback, true)
    end
  end
end
