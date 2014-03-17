module Hercule
  class Activity
    attr_reader :id, :start, :stop, :parent_id, :source, :pid, :fields, :description, :async

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
      @async = source['@async']

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
      entries if options and options[:with_entries]
      super
    end

    def self.find(id)
      response = search(filter: { term: { '_id' => id } })
      response.items.first
    end

    def self.find_by_parents(parent_ids)
      response = search(filter: { terms: { '@parent' => parent_ids } })
      # FIXME: fetch the entries of all activities in one query
      response.items
    end

    def self.query(qs, base_query = {})
      query = base_query
      query[:sort] = [ { '@start' => { order: 'desc' } } ]
      query[:query] = {
        query_string: {
          default_field: '@description',
          default_operator: 'AND',
          query: qs
        }
      } unless qs.blank?

      search(query)
    end

    def self.search(q)
      Result.new Backend.search q, type: 'activity'
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
end

