require "bundler"
Bundler.require(:default)

class Royageur
  class Web < Sinatra::Base
    get "/" do
      @vmstat = Vmstat.snapshot
      slim :index
    end

    get "/search" do
      @query = params[:query]
      @pages = []
      if @query
        DbPage.all.each do |page|
          if page.title.downcase.include?(@query.downcase)
            @pages << page
          end
        end
      end
      slim :search
    end

    get "/style.css" do
      sass :style
    end

    get "/indexer/new" do
      Royageur::Crawler.new#(cpu*2 threads)
      redirect "/"
    end

    get "/indexer/stop/:id" do
      Royageur::POOL.each do |indexer|
        if indexer.id == params[:id]
          indexer.live = false
          Royageur::POOL.delete(indexer)
        end
      end
      redirect "/"
    end
  end
end