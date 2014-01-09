class Activity
  def self.index
    'poirot-*'
  end

  def self.find(id)
    query = {
      size: 1000,
      fields: [ '@start', '@end', '@parent', '@pid', '@source' ],
      filter: {
        and: [
          { term: { '_id' => id } },
          { term: { '_type' => 'activity' } }
        ]
      }
    }
    response = Elasticsearch.client.search index: index, body: query
    puts "Query took #{response['took']} ms"

    hit = response['hits']['hits'].first
    if hit
      fields = hit['fields']
      start = fields['@start']
      stop = fields['@end']
      parent = fields['@parent']
      source = fields['@source']
      pid = fields['@pid']
      activity = new id: id, start: start, stop: stop, parent_id: parent, source: source, pid: pid
      activity
    else
      nil
    end
  end

  def self.find_by_parents(parent_ids)
    query = {
      size: 1000,
      fields: [ '@start', '@end', '@parent', '@pid', '@source' ],
      filter: {
        and: [
          { terms: { '@parent' => parent_ids } },
          { term: { '_type' => 'activity' } }
        ]
      }
    }
    response = Elasticsearch.client.search index: index, body: query
    puts "Query took #{response['took']} ms"

    # FIXME: fetch the entries of all activities in one query
    response['hits']['hits'].map do |hit|
      id = hit['_id']
      fields = hit['fields']
      start = fields['@start']
      stop = fields['@end']
      parent = fields['@parent']
      source = fields['@source']
      pid = fields['@pid']
      activity = new id: id, start: start, stop: stop, parent_id: parent, source: source, pid: pid
      activity
    end
  end

  attr_reader :id, :entries, :start, :stop, :parent_id, :source, :pid

  def initialize(params = {})
    @id = params[:id]
    @parent_id = params[:parent_id]
    @start = params[:start]
    @stop = params[:stop]
    @source = params[:source]
    @pid = params[:pid]
    @entries = params[:entries] || find_entries
  end

  def inspect
    "<Activity #{id}>"
  end

  def parent
    if @parent_id
      self.class.find(@parent_id)
    else
      nil
    end
  end

  private

  def find_entries
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
    response = Elasticsearch.client.search index: self.class.index, body: query
    puts "Query took #{response['took']} ms"
    map_entries(response['hits']['hits'])
  end

  def map_entries(hits)
    hits.map do |e|
      fields = e['fields']
      {
        timestamp: fields['@timestamp'],
        level: fields['@level'],
        source: fields['@source'],
        pid: fields['@pid'],
        message: fields['@message']
      }
    end
  end
end

