class LogController < ApplicationController
  def index
    respond_to do |format|
      format.html
      format.json {
        from = params[:from] || 0
        page_size = 20
        begin
          result = entries(params[:q], from, page_size)
          render json: { result: 'ok', entries: result[:entries], total: result[:total] }.to_json
        rescue => e
          response = JSON.parse(e.message[6..-1])
          render json: { result: 'error', body: response['error'] }.to_json
        end
      }
    end
  end

  private

  def entries(qs, from, page_size)
    query = {
      size: page_size,
      from: from,
      sort: [ '@timestamp' ],
      filter: {
        bool: {
          must: [
            [term: { '_type' => 'logentry' }]
          ]
        }
      }
    }
    unless qs.blank?
      query[:query] = {
        query_string: {
          default_field: '@message',
          query: qs
        }
      }
    end
    response = Elasticsearch.client.search index: 'poirot-*', body: query
    puts "Query took #{response['took']} ms"
    {
      total: response['hits']['total'],
      entries: response['hits']['hits'].map do |hit|
        entry = hit['_source']
        {
          logtime: entry['@timestamp'],
          activity: entry['@activity'],
          pid: entry['@pid'],
          level: entry['@level'],
          source: entry['@source'],
          message: entry['@message']
        }
      end
    }
  end
end

