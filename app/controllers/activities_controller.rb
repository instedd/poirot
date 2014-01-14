class ActivitiesController < ApplicationController
  def index
    respond_to do |format|
      format.html
      format.json {
        from = params[:from] || 0
        page_size = 20
        begin
          result = activities(params[:q], from, page_size)
          render json: { result: 'ok', activities: result[:activities], total: result[:total] }.to_json
        rescue => e
          response = JSON.parse(e.message[6..-1])
          render json: { result: 'error', body: response['error'] }.to_json
        end
      }
    end
  end

  def show
    respond_to do |format|
      format.html
      format.json {
        activity = Activity.find(params[:id])

        if activity
          main = map_activity(activity)
          data = [main]
          
          q = [main]
          while not q.empty?
            ids = q.map do |hash| hash[:id] end
            l = Activity.find_by_parents(ids)
            q = l.map do |activity| map_activity(activity) end
            data = data + q
          end
        else
          data = []
        end
        render json: data
      }
    end
  end

  private

  def map_activity(activity)
    {
      id: activity.id,
      start: activity.start,
      stop: activity.stop,
      parent_id: activity.parent_id,
      source: activity.source,
      pid: activity.pid,
      fields: activity.fields,
      description: activity.description,
      entries: activity.entries
    }
  end

  def activities(qs, from, page_size)
    query = {
      size: page_size,
      from: from,
      sort: [ '@start' ],
      filter: {
        bool: {
          must: [
            [term: { '_type' => 'activity' }]
          ]
        }
      }
    }
    unless qs.blank?
      query[:query] = {
        query_string: {
          default_field: '@description',
          query: qs
        }
      }
    end
    response = Elasticsearch.client.search index: 'poirot-*', body: query
    puts "Query took #{response['took']} ms"
    {
      total: response['hits']['total'],
      activities: response['hits']['hits'].map do |hit|
        activity = hit['_source']
        {
          id: hit['_id'],
          start: activity['@start'],
          stop: activity['@end'],
          source: activity['@source'],
          parent: activity['@parent'],
          description: activity['@description'],
          fields: activity['@fields']
        }
      end
    }
  end
end

