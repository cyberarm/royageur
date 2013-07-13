class Royageur
  class Crawler
    def initialize
      Thread.new do
        indexer = Royageur::Indexer.new
        Thread.current[:indexer] = indexer
        Royageur::POOL << Thread.current
        indexer.run
      end
    end
  end
end