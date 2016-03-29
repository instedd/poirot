@app.directive 'pAttrTable', ['$http', ($http) ->
  restrict: 'E'
  templateUrl: 'attr_table.html'
  scope:
    attribute: '=attribute'
    query: '='
    filters: '='
    since: '='
    type: '@'

  link: (scope) ->
    for filter in scope.filters
      if filter.attr == scope.attribute
        scope.currentFilter = filter
        break

    scope.isNumeric = ['long', 'integer', 'short', 'byte', 'double', 'float'].indexOf(scope.attribute.type) >= 0

    scope.kind = if scope.isNumeric then 'histogram' else 'table'

    if scope.currentFilter? && scope.currentFilter.type == 'range'
      scope.range = angular.copy(scope.currentFilter.range)

    reload = () ->
      attr = scope.attribute
      qs = scope.query
      since = scope.since

      for filter in scope.filters when filter.type == 'term'
        qs += " #{filter.attr.name}:#{filter.value}" unless filter.attr == attr

      $http.get("/#{scope.type}/attributes/#{attr.name}/values?q=#{escape(qs)}&since=#{since}").
        success (data) ->
          scope.values = data

      if scope.isNumeric
        $http.get("/#{scope.type}/attributes/#{attr.name}/histogram").
          success (data) ->
            scope.histogram = data

    scope.$watch '[query, filters, since]', reload, true

    removeCurrentFilter = ->
      if scope.currentFilter
        index = scope.filters.indexOf(scope.currentFilter)
        scope.filters.splice(index, 1)
      scope.currentFilter = null

    scope.addTermFilter = (value) ->
      removeCurrentFilter()
      scope.currentFilter = {attr: scope.attribute, value: value, type: 'term'}
      scope.filters.push(scope.currentFilter)

    scope.removeFilter = (value) ->
      removeCurrentFilter()

    scope.isAttrValueSelected = (value) ->
      scope.currentFilter && scope.currentFilter.value == value

    scope.addRangeFilter = (range) ->
      removeCurrentFilter()
      range  = _.reduce(range, (r, v, k) ->
        r[k] = v if v? && v.length > 0
        r
      , {})
      unless _.isEmpty(range)
        scope.currentFilter = {attr: scope.attribute, range: range, type: 'range'}
        scope.filters.push(scope.currentFilter)
]
