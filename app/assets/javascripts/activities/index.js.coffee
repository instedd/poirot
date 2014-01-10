@app.controller 'ActivityIndexController', ['$scope', ($scope) ->
  $scope.activities = []
  $scope.totalCount = 0
  $scope.page = 1
  $scope.pageSize = 20

  table = $('.activities')

  query = (wait) ->
    queryData = { q: $scope.queryString, from: ($scope.page - 1) * $scope.pageSize }
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
          if a.timestamp > b.timestamp then 1 else -1
        $scope.activities = data.activities

      if wait
        table.off 'transitionend'
        table.on 'transitionend', ->
          finishQuery()
          table.off 'transitionend'
        setTimeout((-> finishQuery()), 100)
      else
        finishQuery()

  $scope.open = (id, evt) ->
    if id
      location.href = "/activities/#{id}"
    if evt
      evt.stopPropagation()

  finishQuery = ->
    $scope.$apply()
    table.removeClass('slideLeft').removeClass('slideRight')
    updatePager()

  $scope.runQuery = () ->
    $scope.page = 1
    query()

  $scope.queryKeyPress = (evt) ->
    if evt.keyCode == 13
      $scope.runQuery()

  $scope.nextPage = () ->
    if $scope.page * $scope.pageSize <= $scope.totalEntries
      $scope.page += 1
      table.addClass('slideLeft')
      query true

  $scope.prevPage = () ->
    if $scope.page > 1
      table.addClass('slideRight')
      $scope.page -= 1
      query true

  $scope.shouldPage = () ->
    $scope.totalCount > $scope.pageSize

  $scope.fromActivity = () ->
    ($scope.page - 1) * $scope.pageSize + 1

  $scope.toActivity = () ->
    Math.min($scope.page * $scope.pageSize, $scope.totalCount)

  updatePager = ->
    pagination = $('.activities-pager')
    scrollBottom = $(document).height() - $(window).height() - $(window).scrollTop()
    if scrollBottom <= 0
      pagination.removeClass('floating')
    else
      pagination.addClass('floating')

  $(window).scroll updatePager

  query()
]

