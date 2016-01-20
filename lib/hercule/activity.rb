module Hercule
  class Activity
    attr_reader :id, :start, :stop, :parent_id, :source, :pid, :fields, :description, :async, :index
    attr_accessor :level, :entries

    def initialize(hit, entries = nil)
      @id = hit['_id']
      @index = hit['_index']

      source = hit['fields'] || hit['_source']

      @start = source['@start']
      @stop = source['@end']
      @parent_id = source['@parent'] || source['@from']
      @source = source['@source']
      @pid = source['@pid']
      @fields = source['@fields']
      @description = source['@description']
      @async = source['@async']

      @entries = entries
    end

    def entries
      @entries ||= LogEntry.find_by_activity(self)
    end

    def self.bulk_load_entries(activities)
      entries_by_activity = LogEntry.find_by_activity(activities).group_by(&:activity)
      activities.each do |activity|
        activity.entries = entries_by_activity[activity.id] || []
      end
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
      entries if options and options[:with_entries]
      super
    end

    def self.find(date, id)
      index = Backend.index_by_date(date)
      result = Hercule::Backend.client.get index: index, type: 'activity', id: id
      Activity.new result
    end

    def self.find_by_parents(date, parent_ids)
      index = Backend.index_by_date(date)
      response = search({filter: { or: [
        { terms: { '@parent' => parent_ids } },
        { terms: { '@from' => parent_ids } }
      ]}}, index: index)
      response.items
    end

    def self.build_query(qs)
      {
        query_string: {
          fields: ['@description^5', '_all'],
          default_operator: 'AND',
          query: qs
        }
      }
    end

    def self.query(qs, base_query = {}, options = {})
      query = base_query
      query[:sort] = [ { '@start' => { order: 'desc' } } ]
      query[:query] = build_query(qs) unless qs.blank?

      search(query, options)
    end

    def self.search(q, options = {})
      options[:type] = 'activity'
      Result.new Backend.search q, options
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

      def with_levels
        levels_search = {
          query: { terms: { '@activity' => items.map(&:id) } },
          size: 0,
          aggs: {
            activities: {
              terms: { field: '@activity', size: 0 },
              aggs: {
                levels: {
                  terms: { field: '@level', size: 0 }
                }
              }
            }
          }
        }

        indices = items.map(&:index).uniq.join(",")
        levels = Hercule::Backend.search(levels_search, type: 'logentry', index: indices)
        levels_by_activity = Hash[levels['aggregations']['activities']['buckets'].map do |a|
          [a['key'], worst_level(a['levels']['buckets'].map { |l| l['key'] })]
        end]

        items.each do |activity|
          activity.level = levels_by_activity[activity.id] || "info"
        end

        self
      end

      private

      def worst_level(levels)
        %w(fatal critical error warn warning notice info debug).each do |level|
          return level if levels.include?(level)
        end
      end
    end
  end
end

