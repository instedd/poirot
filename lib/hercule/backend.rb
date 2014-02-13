require 'elasticsearch'

module Hercule
  class Backend
    def self.client
      @client ||= Elasticsearch::Client.new
    end

    def self.search_all(body, options = {})
      options[:index] ||= all_indices
      options[:body] = body
      response = self.client.search options
      puts "Query took #{response['took']} ms: #{body}"
      response
    end

    def self.all_indices
      "poirot-*"
    end
  end
end

