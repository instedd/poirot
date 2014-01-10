function Flow(containerId) {

    var _self = this;
    var _container = document.getElementById(containerId);
    var _svg = Snap("#" + containerId);
    var _background;
    var _flow;
    var _connector;
    var _targetAt;
    var _height = 0;
    var _width = 0;
    var _circleRadius = 4;
    var _circleStroke = 2;
    var _curveRadius = 6;
    var _laneWidth = 25;
    var _slotHeight = _circleRadius * 2 + _curveRadius * 2;
    var _interval = [];
    var _lanes = [];
    var _levels = [];
    var _activities = [];
    var _events = [];
    var _selected;
    var _min;
    var _max;
    var _scroll = 0;
    var _contentHeight = 0;
    var _windowHeight = 0;
            
    _self.setScroll = function(scroll, contentHeight, windowHeight) {
        _scroll = scroll;
        _contentHeight = contentHeight;
        _windowHeight = windowHeight;
        var value = Math.max(0, Math.min(1, _scroll / (_contentHeight - _windowHeight)));
        if(_flow != undefined) {
            var margin = _slotHeight / 2 + _circleRadius;
            var flowHeight = _flow.getBBox().height + margin;
            var scrollHeight = _height - flowHeight;
            if(_height >= flowHeight) {
                value = 0;
            }
            var offset = (value * scrollHeight + margin);
            _flow.attr({
                transform: "t0 " + offset
            });
            _connector.clear();
            if(_selected != undefined && _targetAt != undefined) {
                var start = {x:(_selected.level + 0.5) * _laneWidth, y:_selected.slot * _slotHeight + offset};
                var end = {x:_width, y:_targetAt - _scroll};
                var pivot = {x:(start.x + end.x) / 2, y:(start.y + end.y) / 2};
                var commands = "M" + start.x + "," + start.y;
                commands += "Q" + ((start.x + pivot.x) / 2) + " " + start.y + " " + pivot.x + " " + pivot.y;
                commands += "Q" + ((pivot.x + end.x) / 2) + " " + end.y + " " + end.x + " " + end.y;
                var connector = _svg.path(commands);
                connector.attr({
                    fill:"none",
                    stroke:_activities[_selected.activity].color,
                    strokeWidth:getStrokeWidth(0),
                    "stroke-linecap":"round",
                    "pointer-events":"none"
                });
                _connector.add(connector);
            }
        }
    }

    _self.selectById = function(id) {
        if(_selected != undefined && _selected.id == id) {
            _selected = undefined;
            invalidate();
            return;
        }
        _events.every(function (entry) {
            if(entry.id == id) {
                _selected = entry;
                invalidate();
                return false;
            } else {
                return true;
            }
        });
    }

    _self.setTargetAt = function(y) {
        _targetAt = y;
        _self.setScroll(_scroll, _contentHeight, _windowHeight);
    }

    _self.render = function() {
        resetInterval();
        _svg.clear();
        _background = _svg.g();
        var boundingBox = {x:0, y:0, width:0, height:0};
        _lanes.forEach(function (entry) {
            var lane = drawLane(entry.length, boundingBox.x + boundingBox.width, 0, _height);
            _background.add(lane);
            boundingBox = lane.getBBox()
        });
        _width = boundingBox.x + boundingBox.width + _laneWidth;
        _container.setAttribute("width", _width + "px");
        _flow = _svg.g();
        _activities.forEach(function(entry) {
            var activity = drawActivity(entry);
            _flow.add(activity);
        });
        _connector = _svg.g();
        _self.setScroll(_scroll, _contentHeight, _windowHeight);
    }

    _self.setData = function(data) {
        _lanes = [];
        _levels = [];
        var level = 0;
        data.lanes.forEach(function(lane) {
            var subLanes = []
            lane.forEach(function(subLane) {
                subLanes.push(subLane);
                _levels[subLane] = level;
                level++;
            });
            _lanes.push(subLanes);
        });
        _activities = [];
        _events = []
        for (var i = data.activities.length - 1; i >= 0; i--) {
            var activity = data.activities[i];
            _activities[activity.id] = {id:activity.id, color:activity.color, events:[]};
        };
        data.events.sort(function (a,b){
            return a.time - b.time}
        );
        var slot = 0;
        var parent;
        data.events.forEach(function (entry) {
            switch(entry.type) {
                case "branch":
                    activity = _activities[entry.child];
                    parent = entry.activity;
                    break;
                case "merge":
                    activity = _activities[entry.child];
                    parent = entry.activity;
                    break;
                case "event":
                    activity = _activities[entry.activity];
                    parent = undefined;
                    break;
            }
            var event = {activity:entry.activity, id:entry.id, slot:slot, time:entry.time, lane:entry.lane, level:_levels[entry.lane], parent:parent};
            _events.push(event);
            activity.events.push(event);
            slot++;
        });
        _min = Number.MAX_VALUE;
        _max = 0;
        _activities.forEach(function (activity) {
            var  lastEvent;
            activity.events.forEach(function (event) {
                if( lastEvent != undefined) {
                    var offset = event.time -  lastEvent.time;
                    _min = Math.min(_min, offset);
                    _max = Math.max(_max, offset);
                }
                lastEvent = event;
            })
        });
        
        invalidate();
    }

    _self.setHeight = function (height) {
        _height = height;
        invalidate();
    }

    function invalidate() {
        resetInterval();
        _interval = setInterval(_self.render, 40);
    }

    function resetInterval() {
        if(_interval != undefined) {
            clearInterval(_interval);
        }
        _interval = undefined;
    }

    function drawLane(levels, x, y, height) {
        lane = _svg.g();
        var strokeWidth = 1;
        var width = levels * _laneWidth;
        var rect = _svg.rect(0, 0, width, height);
        rect.attr({
            fill:"#e0e0e0",
        });
        lane.add(rect);
        var subLaneWidth = width / levels;
        for (var i = 1; i < levels; i++) {
            var laneX = Math.round(i * subLaneWidth) + strokeWidth / 2;
            var line = _svg.line(laneX, 0, laneX, height);
            line.attr({
                stroke:"#f0f0f0",
                strokeWidth:strokeWidth,
                strokeDasharray:"4,2"
            });
            lane.add(line);
        }
        line = _svg.line(width, 0, width, height);
        line.attr({
            stroke:"#ffffff",
            strokeWidth:strokeWidth * 2,
        });
        lane.add(line);
        lane.attr({
            transform: "t" + x + " " + y
        });
       return lane;
    }

    function drawActivity(data) {
        var positions = [];
        var  lastEvent;
        var activity = _svg.g();
        data.events.forEach(function(event) {
            event.position = {x:_laneWidth * (event.level + 0.5),  y:event.slot * _slotHeight};
            if( lastEvent != undefined) {
                var commands = "M" +  lastEvent.position.x + " " +  lastEvent.position.y;
                var jump = event.level -  lastEvent.level;
                var curvePoints;
                if(jump) {
                    if(jump > 0) {
                        curvePoints = [
                            {x: lastEvent.position.x, y: lastEvent.position.y + _circleRadius},
                            {x: lastEvent.position.x + _curveRadius, y: lastEvent.position.y + _circleRadius + _curveRadius},
                            {x:event.position.x - _curveRadius, y: lastEvent.position.y + _circleRadius + _curveRadius},
                            {x:event.position.x, y: lastEvent.position.y + _circleRadius + _curveRadius * 2}
                        ]
                    } else {
                        curvePoints = [
                            {x: lastEvent.position.x, y:event.position.y - _circleRadius - _curveRadius * 2},
                            {x: lastEvent.position.x - _curveRadius, y:event.position.y - _circleRadius - _curveRadius},
                            {x:event.position.x + _curveRadius, y:event.position.y - _circleRadius - _curveRadius},
                            {x:event.position.x, y:event.position.y - _circleRadius}
                        ]
                    }
                    commands += "L" + curvePoints[0].x + " " + curvePoints[0].y;
                    commands += "Q" + curvePoints[0].x + " " + curvePoints[1].y + " " + curvePoints[1].x + " " + curvePoints[1].y;
                    commands += "L" + curvePoints[2].x + " " + curvePoints[2].y;
                    commands += "Q" + curvePoints[3].x + " " + curvePoints[2].y + " " + curvePoints[3].x + " " + curvePoints[3].y;
                    commands += "L";
                } else {
                    commands += "L";
                }
                commands += event.position.x + " " + event.position.y;
                var path = _svg.path(commands);
                path.attr({
                    fill:"none",
                    stroke:data.color,
                    strokeWidth: getStrokeWidth((event.time - lastEvent.time - _min) / (_max - _min))
                });
                activity.add(path);
                commands = "M";
            }
             lastEvent = event;
        });
        data.events.forEach(function(event) {
            var selected = _selected != undefined && _selected.id == event.id;
            var circle = _svg.circle(event.position.x, event.position.y, _circleRadius * (selected? 2 : 1));
            circle.attr({
                fill:event.parent != undefined? _activities[event.parent].color : "#ffffff",
                stroke:data.color,
                strokeWidth:_circleStroke,
                cursor: "pointer"
            });
            circle.eventId = event.id;
            circle.mouseover(circleMouseOverHandler);
            circle.mouseout(circleMouseOutHandler);
            circle.click(circleClickHandler);
            activity.add(circle);
            if(selected) {
                var innerCircle = _svg.circle(event.position.x, event.position.y, _circleRadius);
                innerCircle.attr({
                    fill:data.color,
                    "pointer-events":"none"
                });
                activity.add(innerCircle);
            }
        });
        return activity;
    }

    function getStrokeWidth(value) {
        return _circleStroke + (_circleRadius * 2 - _circleStroke) * value;
    }

    function circleMouseOverHandler(e) {
        if(_selected == undefined || _selected.id != this.eventId) {
            this.attr({
                r:_circleRadius + _circleStroke
            });
        }
    }

    function circleMouseOutHandler(e) {
        if(_selected == undefined || _selected.id != this.eventId) {
            this.attr({
                r:_circleRadius
            });
        }
    }

    function circleClickHandler(e) {
        _self.dispatchEvent(new Event(Event.SELECT, {id:this.eventId}));
    }

    invalidate();
}

Flow.extends(EventDispatcher);
            