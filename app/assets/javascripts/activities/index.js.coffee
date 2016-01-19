@app.controller 'ActivityIndexController', ['$scope', '$http', ($scope, $http) ->
  $scope.activities = []
  $scope.totalCount = 0
  $scope.page = 1
  $scope.pageSize = 20
  $scope.selectedInterval = 1
  $scope.filters = []

  TIME_INTERVALS = [
    {name:"1 hour", hours: 1},
    {name:"3 hours", hours: 3},
    {name:"6 hours", hours: 6},
    {name:"12 hours", hours: 12},
    {name:"1 day", hours: 24},
    {name:"3 days", hours: 72},
    {name:"1 week", hours: 168},
    {name:"3 weeks", hours: 504},
    {name:"ever", hours: null}
  ]

  table = $('.activities')

  $http.get("/activities/attributes").
    success (data) ->
      $scope.attributes = data
      $scope.selectedAttr = data[0]

  $scope.selectedAttr = null
  $scope.selectedAttrValues = null

  saveState = ->
    if window.sessionStorage
      window.sessionStorage.activitiesQuery = $scope.queryString
      window.sessionStorage.selectedInterval = $scope.selectedInterval

  loadState = ->
    if window.sessionStorage
      $scope.queryString = $scope.queryStringInput = window.sessionStorage.activitiesQuery || ''
      $scope.selectedInterval = window.sessionStorage.selectedInterval || 1

  query = () ->
    qs = $scope.queryString
    for filter in $scope.filters
      qs += " #{filter.attr.name}:#{filter.value}"

    queryData = { q: qs, from: ($scope.page - 1) * $scope.pageSize, since: TIME_INTERVALS[$scope.selectedInterval].hours }
    $.getJSON '/activities', queryData, (data) ->
      if data.result == 'error'
        $scope.activities = []
        $scope.totalCount = 0
        $scope.queryError = true
        console.error(data.body)
      else
        $scope.queryError = false
        $scope.totalCount = data.total
        data.activities = data.activities.sort (a,b) ->
          if a.start < b.start then 1 else -1
        $scope.activities = data.activities

      finishQuery()

  $scope.open = (id, evt) ->
    if id
      location.href = "/activities/#{id}"
    if evt
      evt.stopPropagation()

  $scope.intervals = ->
    TIME_INTERVALS

  $scope.selectedIntervalName = ->
    TIME_INTERVALS[$scope.selectedInterval].name

  $scope.selectedIntervalValue = ->
    TIME_INTERVALS[$scope.selectedInterval].hours

  $scope.selectInterval = (i) ->
    $scope.selectedInterval = i
    query()

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

  $scope.$watch '[queryString, filters]', $scope.runQuery, true

  $scope.removeFilterAt = (index) ->
    $scope.filters.splice(index, 1)

  $scope.nextPage = () ->
    if $scope.page * $scope.pageSize <= $scope.totalCount
      $scope.page += 1
      query()

  $scope.prevPage = () ->
    if $scope.page > 1
      $scope.page -= 1
      query()

  $scope.shouldPage = () ->
    $scope.totalCount > $scope.pageSize

  $scope.fromActivity = () ->
    ($scope.page - 1) * $scope.pageSize + 1

  $scope.toActivity = () ->
    Math.min($scope.page * $scope.pageSize, $scope.totalCount)

  updatePager = ->
    pagination = $('.pager-footer')
    scrollBottom = $(document).height() - $(window).height() - $(window).scrollTop()
    if scrollBottom <= 0
      pagination.removeClass('floating')
    else
      pagination.addClass('floating')

  $(window).scroll updatePager

  loadState()
]

