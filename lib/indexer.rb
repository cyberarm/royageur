class Royageur
  class Indexer
    include Celluloid
    trap("INT") do
      exit
    end

    attr_reader :id, :status
    attr_accessor :live
    def initialize(life=600.0, live_forever=false)
      Royageur::POOL << self
      @id     = SecureRandom.uuid
      @status = "Initialized"
      @life   = life # ten minutes
      @live   = true
      @live_forever = live_forever
      @start_time=Time.now
    end

    def run
      loop do
        p Time.now-@start_time
        if Time.now-@start_time >= @life or @live == false
          ss "DEAD"
          Royageur::Crawler.new if @live_forever
          Royageur::POOL.delete(self)
          break
        end
        fetch_and_process_page
      end
    end

    def fetch_and_process_page
      fetch_page
    end

    def fetch_page
      dburl = Royageur::DbUrl.first(crawled: false, allowed: true)
      if dburl
        url = dburl.url
        begin
          @robot = RobotsTXT.new(url)
          ss "Allowed at #{url}? #{@robot.allowed?}"

          if @robot.allowed?
            ss "Resting #{@robot.crawl_delay} seconds"
            sleep(@robot.crawl_delay) # Follow crawl delay if present, sleep for 1.5 seconds if no crawl delay.
  
            ss "Fetching headers: #{url}"
            request = Typhoeus.head(url)
            if request.headers["Content-Type"] && request.headers["Content-Type"].include?("text/html")
              begin
                ss "Resting #{@robot.crawl_delay} seconds"
                sleep(@robot.crawl_delay) # Follow crawl delay if present, sleep for 1.5 seconds if no crawl delay.

                ss "Fetching #{url}"
                connection = Typhoeus.get(url, followlocation: true, connecttimeout: 20)
                ss "Completed fetch in #{connection.total_time}s"
                dburl.update(crawled: true, url: connection.effective_url, crawled_at: Time.now)
                dburl.errors.each do |e|
                  puts e
                  if e.include?("Url is already taken")
                    ss "Deleting duplicate URL"
                    dburl.destroy
                  else
                    puts "Aborting..."
                    abort("DATABASE ERROR")
                  end
                end
  
                process_page(connection, connection.total_time)
              rescue Timeout::Error
                dburl.update(crawled: true) if dburl
              end
            else
              dburl.update(allowed: false) if dburl
            end
          else
            ss "Not allowed at #{url}"
            dburl.update(allowed: false) if dburl
          end
        rescue Encoding::CompatibilityError => e
          ss "error: #{e}, skipping URL"
          dburl.update(crawled: true) if dburl
        end
      else
        ss "No urls in DB that are not crawled"
      end
    end

    def db_update_failed(db)
      puts "========================="
      puts "|Database update failed!|"
      puts "========================="
      puts "Errors:"
      db.errors.each do |e|
        puts e
      end
      puts "========================="
    end

    # Add page to the DB
    def process_page(page, time)
      ss "Process page that fetched in #{time} seconds"
      unless page.nil?
        title = Nokogiri::HTML.parse(page.body).css('title').inner_text if Nokogiri::HTML.parse(page.body).css('title')
        title = "[Unknown]" unless Nokogiri::HTML.parse(page.body).css('title')
        body  = Nokogiri::HTML.parse(page.body).css('body').inner_text
        marshaled_page = Marshal.dump(page)

        DbPage.create(title: title, body: body, page: marshaled_page, time: time, url: page.effective_url)
        ss "Starting search for anchor tags"
        search_and_add_urls(page, page.body)
      else
        raise "FAILED, BAD PROGRAM, BAD PROGRAM: index.rb#79"
      end
    end

    # Find and add anchor tags to DB
    def search_and_add_urls(page, body)
      document = Nokogiri::HTML(body)
      document.css('a').each do |url|
        if url['href'] && url['href'].start_with?('http')
          DbUrl.create(url: url['href'])
          ss "Adding #{url['href']} to DbUrl"

        elsif url['href'] && url['href'].start_with?('/')
          DbUrl.create(url: "#{URI.parse(page.effective_url).scheme}://#{URI.parse(page.effective_url).host}#{url['href']}")
          ss "Adding #{URI.parse(page.effective_url).scheme}://#{URI.parse(page.effective_url).host.sub(/(\/)+$/, '')}#{url['href']} to DbUrl"
        end
      end
    end

    # Set indexer status
    def set_status(status)
      @status = status.to_s
      puts status
    end
    alias_method :ss, :set_status
  end
end