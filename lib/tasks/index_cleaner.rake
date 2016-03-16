desc 'Deletes old indices'
task delete_old_indices: :environment do
  begin
    IndexCleaner.new.delete_old_indices
  rescue Exception => e
    puts "Something went wrong.\n#{e.message}\n#{e.backtrace}"
  end
end

class IndexCleaner

  def initialize
    @save_for = Settings.save_indices_for
    @url_max_length = 1900 # it's usually 2048 but the host needs space too
    @date_format = '%Y.%m.%d'
    @index_prefix = Settings.elasticsearch.index_prefix
    @elasticsearch = Elasticsearch.new @index_prefix
  end

  def indices_names_to_dates(indices_strings)
    indices_names = indices_strings.split("\n")
    date_strings = indices_names.map {|index_name| index_name.gsub(@index_prefix, '')}
    date_strings.map {|date_string| Date.parse(date_string)}
  end

  def too_old_dates(dates)
    threshold = Date.today - @save_for
    dates.select {|date| date < threshold}
  end

  def dates_to_indices_names(dates)
    dates.map {|date| "#{@index_prefix}#{date.strftime(@date_format)}"}
  end

  def delete_old_indices
    indices_string = @elasticsearch.list_indices
    if indices_string.blank?
      puts "No indices available."
      return
    end

    puts "Found indices\n#{indices_string}\n"
    dates = indices_names_to_dates(indices_string)
    old_dates = too_old_dates(dates)
    indices_to_delete = dates_to_indices_names(old_dates)
    if indices_to_delete.empty?
      puts "No indices to delete."
      return
    end
    puts "This indices are too old\n#{indices_to_delete.join("\n")}\n"
    index_name_length = indices_to_delete.first.length
    batch_size = @url_max_length/index_name_length
    indices_to_delete.each_slice(batch_size) do |indices|
      @elasticsearch.delete(indices)
    end
  end

  class Elasticsearch

    def initialize(index_prefix)
      @elasticsearch_url = Settings.elasticsearch.url
      @base_uri = URI.parse(@elasticsearch_url)
      @index_prefix = index_prefix
      @http = Net::HTTP.new(@base_uri.host, @base_uri.port)
    end

    def list_indices
      indices_path = "_cat/indices/#{@index_prefix}*?h=index"
      indices_uri = URI.parse(@elasticsearch_url+indices_path)
      indices_request = Net::HTTP::Get.new(indices_uri.request_uri)
      response = @http.request(indices_request)

      raise "Couldn't get the indices.\n#{response.body}" unless response.is_a?(Net::HTTPSuccess)

      response.body
    end

    def delete(indices)
      delete_uri = URI(@elasticsearch_url+indices.join(','))
      puts "Deleting\n#{indices.join("\n")}"
      delete_request = Net::HTTP::Delete.new(delete_uri.request_uri)
      response = @http.request(delete_request)

      raise "Failed." unless response.is_a?(Net::HTTPSuccess)

      puts "Success!"
    end

  end

end

