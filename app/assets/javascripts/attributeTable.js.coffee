@app.directive 'pAttrTable', ['$http', ($http) ->
  restrict: 'E'
  templateUrl: 'attr_table.html'
  scope:
    attribute: '=attribute'
    query: '='
    filters: '='
    time: '='
    type: '@'

  link: (scope) ->
    for filter in scope.filters
      if filter.attr == scope.attribute
        scope.currentFilter = filter
        break

    reload = () ->
      attr = scope.attribute
      qs = scope.query
      time = scope.time
      for filter in scope.filters
        qs += " #{filter.attr.name}:#{filter.value}" unless filter.attr == attr

      queryData = _.merge({q:qs}, time)

      $.getJSON "/#{scope.type}/attributes/#{attr.name}/values", queryData, (data) ->
        scope.values = data
        scope.$apply()

    scope.$watch '[query, filters, time]', reload, true

    removeCurrentFilter = ->
      if scope.currentFilter
        index = scope.filters.indexOf(scope.currentFilter)
        scope.filters.splice(index, 1)
      scope.currentFilter = null

    scope.addFilter = (value) ->
      removeCurrentFilter()
      scope.currentFilter = {attr: scope.attribute, value: value}
      scope.filters.push(scope.currentFilter)

    scope.removeFilter = (value) ->
      removeCurrentFilter()

    scope.isAttrValueSelected = (value) ->
      scope.currentFilter && scope.currentFilter.value == value
]
