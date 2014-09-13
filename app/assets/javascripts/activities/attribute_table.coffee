@app.directive 'pAttrTable', ['$http', ($http) ->
  restrict: 'E'
  templateUrl: 'attr_table.html'
  scope:
    attribute: '=attribute'
    query: '='
    filters: '='

  link: (scope) ->
    for filter in scope.filters
      if filter.attr == scope.attribute
        scope.currentFilter = filter
        break

    reload = () ->
      attr = scope.attribute
      qs = scope.query
      for filter in scope.filters
        qs += " #{filter.attr.name}:#{filter.value}" unless filter.attr == attr

      $http.get("/activities/attributes/#{attr.name}/values?q=#{escape(qs)}").
        success (data) ->
          scope.values = data

    scope.$watch '[query, filters]', reload, true

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
