@app.controller 'LogEntryController', ['$scope', ($scope) ->

  $scope.logEntry = {}

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

  $scope.openActivity = (id) ->
    location.href = "/activities/#{id}"

  loadData = (data) ->
    $scope.logEntry = data
    $scope.cssClass = "level-#{data.level.toLowerCase()}"
    $scope.metadata = $.extend data.fields,
      id: data.id
      timestamp: formatTimestamp(data.timestamp)
      pid: data.pid
      source: data.source
      tags: data.tags.join(', ') || 'none'

    $scope.$apply()

  formatTimestamp = (ts) ->
    date = new Date(ts)
    h = date.getUTCHours()
    m = date.getUTCMinutes()
    s = date.getUTCSeconds()
    ms = date.getUTCMilliseconds()

    fill = (n) ->
      if n <= 9 then '0' + n else n

    "#{date.toDateString()}, #{h}:#{fill m}:#{fill s}.#{ms} UTC"

  # load initial set of data
  $.ajax
    dataType: 'json',
    url: location.href,
    cache: false,
    success: loadData
]

