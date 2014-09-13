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
      search[:query] = Hercule::Activity.build_query(params[:q])
    end

    result = Hercule::Backend.search(search, type: 'activity')
    render json: result['aggregations']['attr_values']['buckets']
  end
end
