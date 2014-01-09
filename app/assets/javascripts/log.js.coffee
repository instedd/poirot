@app.controller 'LogController', ['$scope', ($scope) ->
  $scope.entries = []
  $scope.totalEntries = 0
  $scope.page = 1
  $scope.pageSize = 20

  table = $('.log-entries')

  query = (wait) ->
    queryData = { q: $scope.queryString, from: ($scope.page - 1) * $scope.pageSize }
    $.getJSON '/log', queryData, (data) ->
      if data.result == 'error'
        $scope.entries = []
        $scope.totalEntries = 0
        $scope.queryError = true
        console.error(data.body)
      else
        $scope.queryError = false
        $scope.totalEntries = data.total
        data.entries = data.entries.sort (a,b) ->
          if a.timestamp > b.timestamp then 1 else -1
        $scope.entries = addCssClasses(data.entries)

      if wait
        table.off 'transitionend'
        table.on 'transitionend', ->
          finishQuery()
          table.off 'transitionend'
        setTimeout((-> finishQuery()), 100)
      else
        finishQuery()

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

  addCssClasses = (data) ->
    addCssEntry(entry) for entry in data

  addCssEntry = (entry) ->
    entry.cssClass = "level-#{entry.level}"
    entry

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
    $scope.totalEntries > $scope.pageSize

  $scope.fromEntry = () ->
    ($scope.page - 1) * $scope.pageSize + 1

  $scope.toEntry = () ->
    Math.min($scope.page * $scope.pageSize, $scope.totalEntries)

  updatePager = ->
    pagination = $('.log-pager')
    scrollBottom = $(document).height() - $(window).height() - $(window).scrollTop()
    if scrollBottom <= 0
      pagination.removeClass('floating')
    else
      pagination.addClass('floating')

  $scope.openActivity = (entry) ->
    if entry.activity.toLowerCase() != 'undefined'
      location.href = "/activities/#{entry.activity}"

  $(window).scroll updatePager

  query()
]

