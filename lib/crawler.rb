class Royageur
  class Crawler
    def initialize
      indexer = Royageur::Indexer.supervise
      Royageur::POOL << indexer
      indexer.actors.first.async.run
    end
  end
end