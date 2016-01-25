@app.controller 'LogEntriesController', ['$scope', '$http', ($scope, $http) ->
  $scope.entries = []
  $scope.totalEntries = 0
  $scope.page = 1
  $scope.pageSize = 20
  $scope.tooltip = message: '', visible: false, style: {}
  $scope.filters = []

  table = $('.log-entries')
  viewport = $('.grid-viewport')

  $http.get("/log_entries/attributes").
    success (data) ->
      $scope.attributes = data
      $scope.selectedAttr = data[0]

  $scope.selectedAttr = null
  $scope.selectedAttrValues = null

  saveState = ->
    if window.sessionStorage
      window.sessionStorage.entriesQuery = $scope.queryString

  loadState = ->
    if window.sessionStorage
      $scope.queryString = $scope.queryStringInput = window.sessionStorage.entriesQuery || ''

  $scope.showTooltip = (entry, event) ->
    cell = $(event.target)
    if event.target.scrollWidth > cell.outerWidth()
      position = cell.position()
      left = position.left
      top = position.top + viewport.scrollTop()
      $scope.tooltip.message = entry.message
      $scope.tooltip.cssClass = entry.cssClass
      $scope.tooltip.style = left: left, top: top, width: cell.outerWidth()
      $scope.tooltip.visible = true

  $scope.hideTooltip = () ->
    $scope.tooltip.visible = false

  query = () ->
    qs = $scope.queryString
    for filter in $scope.filters
      qs += " #{filter.attr.name}:#{filter.value}"

    queryData = { q: qs, from: ($scope.page - 1) * $scope.pageSize, since: $scope.selectedIntervalValue() }
    $.getJSON '/log_entries', queryData, (data) ->
      if data.result == 'error'
        $scope.entries = []
        $scope.totalEntries = 0
        $scope.queryError = true
        console.error(data.body)
      else
        $scope.queryError = false
        $scope.totalEntries = data.total
        data.entries = data.entries.sort (a,b) ->
          if a.timestamp < b.timestamp then 1 else -1
        $scope.entries = addCssClasses(data.entries)

      finishQuery()

  $scope.selectAttribute = (attr) ->
    $scope.selectedAttrValues = null
    if $scope.selectedAttr == attr
      $scope.selectedAttr = null
    else
      $scope.selectedAttr = attr

  finishQuery = ->
    $scope.$apply()
    updatePager()
    saveState()

  $scope.runQuery = () ->
    $scope.page = 1
    query()

  $scope.queryKeyPress = (evt) ->
    if evt.keyCode == 13
      $scope.queryString = $scope.queryStringInput
      console.log($scope.queryString)

  $scope.$watch '[queryString, filters, selectedIntervalValue()]', $scope.runQuery, true

  $scope.removeFilterAt = (index) ->
    $scope.filters.splice(index, 1)

  addCssClasses = (data) ->
    addCssEntry(entry) for entry in data

  addCssEntry = (entry) ->
    entry.cssClass = "level-#{entry.level}"
    entry

  $scope.nextPage = () ->
    if $scope.page * $scope.pageSize <= $scope.totalEntries
      $scope.page += 1
      query()

  $scope.prevPage = () ->
    if $scope.page > 1
      $scope.page -= 1
      query()

  $scope.shouldPage = () ->
    $scope.totalEntries > $scope.pageSize

  $scope.fromEntry = () ->
    ($scope.page - 1) * $scope.pageSize + 1

  $scope.toEntry = () ->
    Math.min($scope.page * $scope.pageSize, $scope.totalEntries)

  updatePager = ->
    pagination = $('.pager-footer')
    scrollBottom = table.height() - viewport.height() - viewport.scrollTop()
    if scrollBottom <= 0
      pagination.removeClass('floating')
    else
      pagination.addClass('floating')

  $scope.openActivity = (entry) ->
    if entry.activity.toLowerCase() != 'undefined'
      location.href = "/activities/#{entry.activity}"

  $scope.open = (id, evt) ->
    location.href = "/log_entries/#{id}" if id
    evt.stopPropagation() if evt

  viewport.on 'scroll', updatePager

  loadState()
  query()
]

