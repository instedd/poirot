require 'elasticsearch'

module Hercule
  class Backend
    def self.client
      @client ||= Elasticsearch::Client.new
    end

    def self.client=(client)
      @client = client
    end

    def self.search(body, options = {})
      body[:from] ||= 0
      body[:size] ||= 1000
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

