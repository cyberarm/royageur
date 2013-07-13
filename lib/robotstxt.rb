class Royageur
  class RobotsTXT
    def initialize(url)
      @indexer = WebRobots.new("#{Royageur::USER_AGENT} #{Royageur::VERSION}")
      @url  = url
    end

    def allowed?
      @indexer.allowed?(@url)
    end

    def crawl_delay
      @indexer.crawl_delay(@url)
    end
  end
end