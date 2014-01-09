class Activity
  def self.index
    'poirot-*'
  end

  def self.find(id)
    query = {
      size: 1000,
      sort: [ '@timestamp' ],
      fields: [ '@timestamp', '@level', '@source', '@pid', '@message' ],
      filter: {
        and: [
          { term: { '@activity' => id } },
          { term: { '_type' => 'logentry' } }
        ]
      }
    }
    response = Elasticsearch.client.search index: index, body: query
    puts "Query took #{response['took']} ms"
    entries = response['hits']['hits'].map do |e|
      fields = e['fields']
      {
        timestamp: fields['@timestamp'],
        level: fields['@level'],
        source: fields['@source'],
        pid: fields['@pid'],
        message: fields['@message']
      }
    end
    activity = new id: id, entries: entries
    activity
  end

  attr_reader :id, :entries

  def initialize(params = {})
    @id = params[:id]
    @entries = params[:entries]
  end

  def inspect
    "<Activity #{id}>"
  end
end

