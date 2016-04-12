@app.directive 'histogram', () ->
  restrict: 'E'
  templateUrl: 'histogram.html'
  scope:
    onHistogramDataArrived: '&'
  link: (scope, element, attrs) ->
    config =
      margin_percentage: 0.08
      bars_height_percentage: 0.8
      axis_height_percentage: 0.2

    element_parent = element.parent()
    histogram =
      height: element_parent.height()
      width: element_parent.width()

    loading = element.find('.loading')
    # add svg and set/inherit dimensions
    svg_element = element.find('svg')
    svg_element.hide()
    svg = d3.select('svg')
      .attr('width', histogram.width)
      .attr('height', histogram.height)

    # axis config
    axis_config = new () ->
      this.ticks = 9
      this.margin = histogram.width*config.margin_percentage
      this.height = histogram.height*config.axis_height_percentage
      this.width = histogram.width-this.margin
      y = histogram.height*config.bars_height_percentage
      x = this.margin/2
      this.translate_str = 'translate(' + x + ', ' + y + ')'

    # bars config
    bars_config = new () ->
      this.margin = histogram.width*config.margin_percentage
      this.height = histogram.height*config.bars_height_percentage
      this.width = histogram.width-this.margin
      this.y = 0
      this.x = this.margin/2
      this.translate_str = 'translate(' + this.x + ', 0)'

    # configure axis scale
    scaleX = d3.time.scale.utc()
      .rangeRound([0, axis_config.width])
      .nice(axis_config.ticks)

    # generate d3 time axis
    axis = d3.svg.axis()
      .scale(scaleX)
      .ticks(axis_config.ticks)
      .orient('bottom')

    # add axis to the svg 
    translate_str = 'translate(' + axis_config.x + ', ' + axis_config.y + ')'
    axis_group = svg.select('#axis')
      .attr('transform', axis_config.translate_str)
      .call(axis)

    # set bars config
    bars = svg.select('#bars')
      .attr('height', bars_config.height)
      .attr('width', bars_config.width)
      .attr('transform', bars_config.translate_str)

    scope.onHistogramDataArrived(
      handler: (data) ->
        loading.hide()
        svg_element.show()

        timestamps = _.map(data, 'timestamp')
        min_timestamp = _.min(timestamps)
        max_timestamp = _.max(timestamps)
        counts = _.map(data, 'count')
        max_count = _.max(counts)

        min_date = new Date(min_timestamp)
        max_date = new Date(max_timestamp)
        scaleX.domain([min_date, max_date])
        axis_group.call(axis)

        bar_width = bars_config.width/data.length
        groups = bars.selectAll('.rect')
          .data(data)

        groups.enter()
          .append('rect')
            .attr('class', 'rect')
            .attr('width', bar_width)
            .attr('height', 0)
            .attr('transform', (d, i) ->
              'translate(' + (bar_width*i) + ', ' + bars_config.height + ')'
            )

        groups.exit()
          .remove()

        groups.transition()
          .attr('transform', (d, i) ->
            'translate(' + (bar_width*i) + ', ' + (bars_config.height-((d.count/max_count)*bars_config.height)) + ')'
          )
          .attr('height', (d, i) -> (d.count/max_count) * bars_config.height)
    )
