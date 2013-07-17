class Royageur
  class Crawler
    def initialize
      indexer = Royageur::Indexer.supervise
      indexer.actors.first.async.run
    end
  end
end