module DataSeeding
  module Commands
    def commit
      throw(:commit, :commit)
    end

    def rollback
      throw(:rollback, :rollback)
    end
  end
end
