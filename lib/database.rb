class Royageur
  class DbUrl
    include DataMapper::Resource
    property :id, Serial
    property :url, Text, unique: true
    property :allowed, Boolean, default: true
    property :crawled, Boolean, default: false
    property :crawled_at, DateTime
  end

  class DbPage
    include DataMapper::Resource
    property :id, Serial
    property :title, Text
    property :url, Text, unique: true
    property :body, Text

    property :status, Integer
    property :time, Float
    property :created_at, DateTime
    property :page, Text
  end  
end