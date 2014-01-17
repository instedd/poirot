class Activity
  attr_reader :id, :start, :stop, :parent_id, :source, :pid, :fields, :description

  def initialize(hit, entries = nil)
    @id = hit['_id']

    source = hit['fields'] || hit['_source']

    @start = source['@start']
    @stop = source['@end']
    @parent_id = source['@parent']
    @source = source['@source']
    @pid = source['@pid']
    @fields = source['@fields']
    @description = source['@description']

    @entries = entries
  end

  def entries
    @entries ||= LogEntry.find_by_activity_id id
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

  def as_json(options = nil)
    # force loading of entries
    entries
    super
  end

  def self.base_query(options = {})
    size = options[:size] || 1000
    from = options[:from] || 0

    query = {
      size: size,
      from: from,
      sort: [ '@start' ],
      filter: {
        and: [
          { term: { '_type' => 'activity' } }
        ]
      }
    }
  end

  def self.find(id)
    query = base_query
    query[:filter][:and] << { term: { '_id' => id } }
    response = Backend.search_all query

    hit = response['hits']['hits'].first
    if hit
      new hit
    else
      nil
    end
  end

  def self.find_by_parents(parent_ids)
    query = base_query
    query[:filter][:and] << { terms: { '@parent' => parent_ids } }
    response = Backend.search_all query
    # FIXME: fetch the entries of all activities in one query
    Result.new(response).items
  end

  def self.query(qs, options = {})
    query = base_query(options)
    query[:query] = { query_string: { default_field: '@description', query: qs } } unless qs.blank?

    Result.new Backend.search_all(query)
  end

  class Result
    attr_reader :response

    def initialize(response)
      @response = response
    end

    def total
      @total ||= @response['hits']['total']
    end

    def items
      @items ||= @response['hits']['hits'].map do |hit|
        Activity.new hit
      end
    end
  end
end

