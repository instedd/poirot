module Elasticsearch
  def self.client
    @client ||= Elasticsearch::Client.new
  end
end

