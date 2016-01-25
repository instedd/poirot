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

      if since = options.delete(:since)
        options[:index] = indices_since(since)
        options[:ignore_unavailable] = true
        options[:allow_no_indices] = true
      end

      options[:index] ||= all_indices
      options[:body] = body
      response = self.client.search options
      puts "Query took #{response['took']} ms: #{options}"
      response
    end

    def self.all_indices
      "poirot-*"
    end

    def self.index_by_date(date)
      if date.is_a?(String)
        date = Time.parse(date)
      end
      date.strftime("poirot-%Y.%m.%d")
    end

    def self.indices_since(since)
      now = Time.now.utc
      indices = []
      loop do
        indices << index_by_date(since)
        since += 1.day
        break if since > now
      end
      indices.join ","
    end
  end
end

