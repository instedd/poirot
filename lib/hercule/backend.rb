require 'elasticsearch'

module Hercule
  class Backend
    def self.client
      @client ||= Elasticsearch::Client.new
    end

    def self.search_all(body)
      response = self.client.search index: all_indices, body: body
      puts "Query took #{response['took']} ms: #{body}"
      response
    end

    def self.all_indices
      "poirot-*"
    end
  end
end

