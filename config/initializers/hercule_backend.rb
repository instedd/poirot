require_relative 'rails_config'

Hercule::Backend.client = Elasticsearch::Client.new host: Settings.elasticsearch.url
