@app.controller 'ActivityIndexController', ['$scope', '$http', ($scope, $http) ->
  $scope.activities = []
  $scope.totalCount = 0
  $scope.page = 1
  $scope.pageSize = 20
  $scope.filters = []
  $scope.histogram_initialized = false

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
      window.sessionStorage.timeModel = JSON.stringify($scope.serializeTimeModel())

  loadState = ->
    if window.sessionStorage
      $scope.queryString = $scope.queryStringInput = window.sessionStorage.activitiesQuery || ''
      $scope.loadTimeModel(JSON.parse(window.sessionStorage.timeModel)) if window.sessionStorage.timeModel?

  query = () ->
    qs = $scope.queryString
    for filter in $scope.filters
      qs += " #{filter.attr.name}:#{filter.value}"

    queryData = _.merge({ q: qs, from: ($scope.page - 1) * $scope.pageSize}, $scope.timeFilter)

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
        $scope.histogram_data = data.bars

      finishQuery()

  $scope.selectAttribute = (attr) ->
    $scope.selectedAttrValues = null
    if $scope.selectedAttr == attr
      $scope.selectedAttr = null
    else
      $scope.selectedAttr = attr

  finishQuery = ->
    $scope.$apply()
    initialize_histogram() unless $scope.histogram_initialized
    drawHistogram()
    updatePager()
    saveState()

  initialize_histogram = ->
    $scope.histogram_initialized = true
    $scope.histogram_values =
      container_height: 100
      margin_left: 15
      margin_right: 15
      date_axis_height: 20
      histogram_height: 80

    container = $("#histogram-results")
    $scope.svg = d3.select("#histogram-results").append("svg")
      .attr("width", container.width())
      .attr("height", $scope.histogram_values.container_height)
    .append("g")

    $scope.scaleX = d3.time.scale.utc()
      .rangeRound([0, container.width()-$scope.histogram_values.margin_left-$scope.histogram_values.margin_right])
      .nice(9)

    $scope.axis = axis  = d3.svg.axis()
      .scale($scope.scaleX)
      .ticks(9)
      .orient("bottom")
  
    $scope.svg.append("g")
      .attr("class", "axis")
      .attr("transform", "translate(" + $scope.histogram_values.margin_left + ", " + $scope.histogram_values.histogram_height + ")")
      .call(axis)

    $scope.bars = $scope.svg.append("g")
      .attr("class", "bars")
      .attr("height", $scope.histogram_values.histogram_height)
      .attr("width", container.width()-$scope.histogram_values.margin_left-$scope.histogram_values.margin_right)
      .attr("transform", "translate(" + $scope.histogram_values.margin_left + ", 0)")

  drawHistogram = ->
    data = $scope.histogram_data
    container = $("#histogram-results")

    timestamps = _.map(data, 'timestamp')
    min_timestamp = _.min(timestamps)
    max_timestamp = _.max(timestamps)
    counts = _.map(data, 'count')
    max_count = _.max(counts)

    min_date = new Date(min_timestamp)
    max_date = new Date(max_timestamp)
    $scope.scaleX.domain([min_date, max_date])
    $scope.svg.selectAll("g .axis").call($scope.axis)

    bar_width = (container.width()-$scope.histogram_values.margin_left-$scope.histogram_values.margin_right)/data.length
    groups = $scope.bars.selectAll(".rect")
      .data(data)

    groups.enter()
      .append("rect")
        .attr("class", "rect")
        .attr("width", bar_width)
        .attr("height", 0)
        .attr("transform", (d, i) ->
          "translate(" + (bar_width*i) + ", " + $scope.histogram_values.histogram_height + ")"
        )

    groups.exit()
      .remove()

    groups.transition()
      .attr("transform", (d, i) ->
        "translate(" + (bar_width*i) + ", " + ($scope.histogram_values.histogram_height-((d.count/max_count)*$scope.histogram_values.histogram_height)) + ")"
      )
      .attr("height", (d, i) -> (d.count/max_count) * $scope.histogram_values.histogram_height)

  $scope.runQuery = () ->
    $scope.page = 1
    query()

  $scope.queryKeyPress = (evt) ->
    if evt.keyCode == 13
      $scope.queryString = $scope.queryStringInput

  $scope.$watch '[queryString, filters, timeFilter]', $scope.runQuery, true

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

