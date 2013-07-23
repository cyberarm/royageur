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
      delay = @indexer.crawl_delay(@url)
      if delay <= 1
        return 1.5
      else
        return delay
      end
    end
  end
end