class Activity
  def self.index
    'logstash-*'
  end

  def self.all
    query = {
      size: 10000,
      fields: [ 'activity', 'logtime', 'message' ],
      filter: {
        bool: {
          must: [
            [term: { 'receiver.module' => 'activity' }],
            [terms: { 'receiver.message' => ['start', 'stop']}]
          ],
          must_not: [
            term: { 'receiver.tags' => '_grokparsefailure' }
          ]
        }
      }
    }
    response = Elasticsearch.client.search index: index, body: query
    puts "Query took #{response['took']} ms"
    activities = {}
    response['hits']['hits'].map do |e|
      source = e['fields']
      id = source['activity']
      activity = activities[id] || {start: nil, stop: nil}
      if source['message'].downcase.start_with?('start')
        activity[:start] = source['logtime']
      else
        activity[:stop] = source['logtime']
      end
      activities[id] = activity
    end
    activities.map do |id, activity|
      new id: id, start: activity[:start], stop: activity[:stop]
    end
  end

  def self.find(id)
    query = {
      size: 1000,
      sort: [ 'logtime' ],
      fields: [ 'logtime', 'level', 'pid', 'module', 'message' ],
      filter: {
        and: [
          { term: { 'receiver.activity' => id } },
          { not: { term: { 'receiver.tags' => '_grokparsefailure' } } }
        ]
      }
    }
    response = Elasticsearch.client.search index: index, body: query
    puts "Query took #{response['took']} ms"
    entries = response['hits']['hits'].map do |e|
      e['fields']
    end
    activity = new id: id, entries: entries
    activity
  end

  attr_reader :id, :start, :stop, :entries

  def initialize(params = {})
    @id = params[:id]
    @start = DateTime.parse(params[:start]) rescue nil
    @stop = DateTime.parse(params[:stop]) rescue nil
    @entries = params[:entries]
  end

  def inspect
    "<Activity #{id}>"
  end

  def overlaps?(other)
    if @start.nil?
      other.start.nil? || other.start < @stop
    elsif @stop.nil?
      other.stop.nil? || other.stop > @start
    else
      (other.stop.nil? || @start < other.stop) && (other.start.nil? || @stop > other.start)
    end
  end

  def <(other)
    if other.start.nil? 
      if @start.nil?
        if other.end.nil?
          if @end.nil?
            @id < other.id
          else
            true
          end
        else
          !@end.nil? && @end < other.end
        end
      else
        false
      end
    else
      @start.nil? || @start < other.start
    end
  end

  def <=>(other)
    if self < other
      -1
    else
      1
    end
  end

  def self.assign_lanes(activities)
    lanes = []
    activities.sort.each do |a|
      lane_index = lanes.find_index do |lane|
        lane.nil? || !a.overlaps?(lane.last) 
      end || lanes.size
      lanes[lane_index] ||= []
      lanes[lane_index] << a
    end
    lanes
  end

  def events
    @events
  end

  def find_events
    query = {
      size: 10000,
      fields: [ 'logtime', 'message', 'activity' ],
      sort: [ 'logtime' ],
      filter: {
        and: [
          { term: { 'receiver.module' => 'activity' } },
          { not: { term: { 'receiver.tags' => '_grokparsefailure' } } },
          {
            or: [
              {
                bool: {
                  must: [
                    [term: { 'receiver.activity' => id }],
                    [terms: { 'receiver.message' => ['start','stop','suspend','resume','transfer']}]
                  ]
                }
              },
              { term: { 'receiver.message' => id } }
            ]
          }
        ]
      }
    }
    response = Elasticsearch.client.search index: self.class.index, body: query
    puts "Query took #{response['took']} ms"
    events = response['hits']['hits'].map do |e|
      source = e['fields']
      type = source['message'].downcase.split(/\s+/).first
      time = source['logtime']
      extra = nil
      if type == 'start'
        @start = time
      elsif type == 'stop'
        @stop = time
      elsif type == 'transfer'
        if source['activity'] == id
          extra = source['message'].downcase.split('from=').second
          type = 'transfer_from'
        else
          extra = source['activity']
          type = 'transfer_to'
        end
      end
      [time, type, extra]
    end
    @events = events
    @events
  end

  def transfers_to
    events.select { |e| e[1] == 'transfer_to' }.map { |e| e[2] }.uniq
  end

  def transfers_from
    events.select { |e| e[1] == 'transfer_from' }.map { |e| e[2] }.uniq
  end
end

