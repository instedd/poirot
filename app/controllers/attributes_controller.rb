class AttributesController < ApplicationController

  def values
    search = {
      size: 0,
      aggs: {
        attr_values: {
          terms: {
            field: params[:id]
          }
        }
      }
    }

    if params[:q].present?
      search[:query] = {
        query_string: {
          default_field: '@description',
          default_operator: 'AND',
          query: params[:q]
        }
      }
    end

    result = Hercule::Backend.search(search)
    render json: result['aggregations']['attr_values']['buckets']
  end
end
