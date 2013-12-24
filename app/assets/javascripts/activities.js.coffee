@app.controller 'ActivityController', ['$scope', ($scope) ->
  $scope.entries = []
  activity = null
  events = []
  spans = []
  arrows = []

  width = $('.explorer').width()
  height = $('.explorer').height()

  axisWidth = 60
  lanesOffset = axisWidth + 10
  lanesWidth = width - lanesOffset
  focusLaneWidth = lanesWidth / 3
  focusLaneOffset = (lanesWidth - focusLaneWidth) / 2

  main = d3.select('.explorer svg')
    .attr('width', width)
    .attr('height', height)

  extent = []
  timeScale = d3.time.scale().range([0, height])
  timeAxis = d3.svg.axis()
    .scale(timeScale)
    .orient('left')
    .ticks(d3.time.minutes, 15)
    .tickFormat(d3.time.format('%H:%M'))
    .tickSize(3, 0, 0)

  main.append('g')
    .attr('transform', "translate(#{axisWidth},0)")
    .attr('class', 'time-axis')
    .call(timeAxis)

  rects = main.append('g')
    .attr('transform', "translate(#{axisWidth},0)")
    .attr('class', 'activity')

  rescale = () ->
    extent = d3.extent(events, (e) -> e.time)
    timeScale.domain([extent[0], extent[1]]).nice()
    extent = (x.getTime() for x in timeScale.domain())

  redraw = () ->
    dt = extent[1] - extent[0]
    timeAxis.scale(timeScale)
    if dt > 20 * 120 * 60000
      timeAxis.ticks(d3.time.hours, 6)
    else if dt > 20 * 60 * 60000
      timeAxis.ticks(d3.time.hours, 2)
    else if dt > 20 * 15 * 60000
      timeAxis.ticks(d3.time.minutes, 30)
    else if dt > 20 * 5 * 60000
      timeAxis.ticks(d3.time.minutes, 15)
    else if dt > 20 * 1 * 60000
      timeAxis.ticks(d3.time.minutes, 5)
    else if dt > 20 * 30000
      timeAxis.ticks(d3.time.minutes, 1)
    else
      timeAxis.ticks(d3.time.seconds, 30)

    if dt > 20 * 120 * 60000
      timeAxis.tickFormat(d3.time.format("%a %H:%M"))
    else if dt > 20 * 30000
      timeAxis.tickFormat(d3.time.format("%H:%M"))
    else
      timeAxis.tickFormat(d3.time.format("%H:%M:%S"))

    main.select('.time-axis').call(timeAxis)
    
    items = rects.selectAll('rect').data(spans)
      .attr('y', spanStart)
      .attr('height', spanHeight)

    items.enter().append('rect')
      .attr('x', focusLaneOffset).attr('width', focusLaneWidth)
      .attr('y', spanStart)
      .attr('height', spanHeight)
      .attr('class', (d) -> if d.main then 'all-activity' else '')

    items.exit().remove()


  spanStart = (d) ->
    if d.start then timeScale(d.start) else timeScale.range()[0]
  spanHeight = (d) ->
    start = spanStart(d)
    end = if d.end then timeScale(d.end) else timeScale.range()[1]
    Math.max(5, end - start)

      
  $scope.zoomIn = () -> zoom 0.5
  $scope.zoomOut = () -> zoom 2

  zoom = (factor) ->
    dt = extent[1] - extent[0]
    mid = (extent[0] + extent[1]) / 2
    extent = [mid - dt / 2 * factor, mid + dt / 2 * factor]
    timeScale.domain(extent)
    redraw()

  dragListener = () ->
    startY = null
    startExtent = extent

    d3.behavior.drag()
      .on('dragstart', () ->
        startY = d3.event.sourceEvent.y
        startExtent = extent
      ).on('drag', () ->
        dy = d3.event.sourceEvent.y - startY
        dt = timeScale.invert(0) - timeScale.invert(dy)
        extent = [startExtent[0] + dt, startExtent[1] + dt]
        timeScale.domain(extent)
        redraw()
      )

  main.call(dragListener())
  

  addCssClasses = (data) ->
    addCssEntry(entry) for entry in data

  addCssEntry = (entry) ->
    entry.cssClass = "level-#{entry.level}"
    entry

  transformEvents = (events) ->
    transformEvent(event) for event in events

  transformEvent = (event) ->
    {
      time: new Date(event[0]).getTime(),
      type: event[1],
      extra: event[2]
    }

  computeSpans = (events) ->
    result = [{}]
    i = j = 0
    main_start = main_end = undefined
    while i < events.length
      if events[i].type == 'start'
        main_start = events[i].time
      else if events[i].type == 'stop'
        main_end = events[i].time

      if events[i].type in ['start', 'resume']
        start = events[i].time
        end = events[i].time
        while j < events.length - 1
          j += 1
          end = events[j].time
          if events[j].type in ['suspend', 'stop'] and events[j].time >= start
            break
        result.push start: start, end: end
      i += 1
    result[0] = start: main_start, end: main_end, main: true
    result

  computeArrows = (events) ->


  $.getJSON location.href, (data) ->
    activity = data
    $scope.entries = addCssClasses(data.entries)
    $scope.$apply()
    events = transformEvents(data.events)
    spans = computeSpans(events)
    arrows = computeArrows(events)

    window.activity = data
    rescale()
    redraw()
]

