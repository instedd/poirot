function Flow(containerId) {

    EventDispatcher.call(this);
    InvalidateElement.call(this);

    var self = this;
    var _container;
    var _svg;
    var _width = 0;
    var _height = 0;
    var _circleRadius = 4;
    var _circleStroke = 2;
    var _curveRadius = 5;
    var _laneWidth = 28;
    var _slotHeight;
    var _timeSlots;
    var _lanes = [];
    var _levels = [];
    var _activities = [];
    var _events = [];
    var _scroll = 0;
    var _contentHeight = 0;
    var _windowHeight = 0;
    var _flow;
    var _selection;
    var _lines;
    var _link;
    var _connectors;
    var _dots;
    var _activity;
    var _event;
    var _targetAt;
    var _backgroundColor = "#e0e0e0";

    function init(containerId) {
        _container = document.getElementById(containerId);
        _svg = Snap("#" + containerId);
        self.slotHeight(_circleRadius * 2 + _curveRadius * 2);
        self.invalidate();
    }

    self.slotHeight = function(value) {
        if(!arguments.length) {
            return _slotHeight;
        } else {
            _slotHeight = value;
            self.invalidate();
        }
    }

    self.setScroll = function(scroll, contentHeight, windowHeight) {
        _scroll = scroll;
        _contentHeight = contentHeight;
        _windowHeight = windowHeight;
        var value = Math.max(0, Math.min(1, _scroll / (_contentHeight - _windowHeight)));
        if(_flow != undefined) {
            var margin = _slotHeight / 2;
            var flowHeight = (_events.length - 1) * _slotHeight + margin * 2;
            var scrollHeight = _height - flowHeight;
            if(_height >= flowHeight) {
                value = 0;
            }
            var offset = value * scrollHeight;
            _flow.attr({
                transform: "t0.5 " + (Math.floor(offset + margin) + 0.5)
            });
            _background.attr({
                transform: "t0 " + (Math.floor(offset))
            });
            _link.clear();
            if(_event != undefined && _targetAt != undefined) {
                var strokeWidth = 1;
                var start = {x:(_event.level + 0.5) * _laneWidth, y:_event.slot * _slotHeight};
                var end = {x:_width, y:_targetAt - _scroll - offset};
                var pivot = {x:(start.x + end.x) / 2, y:(start.y + end.y) / 2};
                var commands = "M" + start.x + "," + start.y;
                commands += "Q" + ((start.x + pivot.x) / 2) + " " + start.y + " " + pivot.x + " " + pivot.y;
                commands += "Q" + ((pivot.x + end.x) / 2) + " " + end.y + " " + end.x + " " + end.y;
                var line = _svg.path(commands);
                _link.attr({
                    fill:"none",
                    stroke:getActivityColor(_activities[_event.activity]),
                    strokeWidth:strokeWidth,
                    pointerEvents:"none"
                });
                _link.add(line);
            }
        }
    }

    self.setHeight = function (height) {
        _height = height;
        self.invalidate();
    }

    self.setTargetAt = function(y) {
        _targetAt = y;
        self.setScroll(_scroll, _contentHeight, _windowHeight);
    }

    self.selectEvent = function(id) {
        if(_event != undefined && _event.id == id) {
            _event = undefined;
            self.invalidate();
            return;
        }
        _event = getEventById(id);
        self.invalidate();
    }

    self.selectActivity = function(id) {
        if(_activity != undefined && _activity.id == id) {
            _activity = undefined;
        } else {
            _activity = _activities[id];
        }
        self.invalidate();
    }

    self.expand = function(target) {
        transform(1.25, target);
    }

    self.contract = function(target) {
        transform(1, target);
    }

    self.data = function(data) {
        _lanes = [];
        _levels = [];
        _activities = [];
        _events = [];
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
        data.activities.forEach(function(entry) {
            _activities[entry.id] = {id:entry.id, color:entry.color, events:[]};
        });
        var indexedEvents = [];
        var index = 0;
        data.events.forEach(function (entry) {
            indexedEvents[entry.id] = index;
            index++;
        });
        data.events.sort(function (a, b) {
            var delta = a.time - b.time;
            if(!delta) delta = indexedEvents[a.id] - indexedEvents[b.id];
            return delta;
        });
        var slot = 0;
        var previous;
        data.events.forEach(function (entry) {
            var activity = _activities[entry.activity];
            var event = {type:entry.type, activity:entry.activity, id:entry.id, slot:slot, time:entry.time, lane:entry.lane, level:_levels[entry.lane], sync:entry.sync, fromNode:entry.fromNode, toNode:entry.toNode, fromActivity:entry.fromActivity, toActivity:entry.toActivity, connect:entry.connect};
            if(event.fromNode != undefined) {
                activity.parent = _activities[getEventById(event.fromNode).activity];
            } else if(event.fromActivity != undefined) {
                activity.parent = _activities[event.fromActivity];
            }
            _events.push(event);
            activity.events.push(event);
            slot++;
        });
        _min = Number.MAX_VALUE;
        _max = 0;
        _timeSlots = [];
       _events.forEach(function (event) {
            if(previous != undefined) {
                var offset = event.time -  previous.time;
                _min = Math.min(_min, offset);
                _max = Math.max(_max, offset);
                _timeSlots.push(offset);
            }
            previous = event;
        });
        self.invalidate();
    }

    self.render = function() {
        _svg.clear();
        _background = _svg.g();
        var offset = 0;
        _lanes.forEach(function (entry) {
            var lane = drawLane(entry.length, offset, 0);
            _background.add(lane);
            offset += entry.length * _laneWidth;
        });
        _width = offset;
        _container.setAttribute("width", _width + "px");
        _flow = _svg.g();
        _lines = _svg.g();
        _selection = _svg.g();
        _link = _svg.g();
        _connectors = _svg.g();
        _dots = _svg.g();
        _flow.add(_lines);
        _flow.add(_selection);
        _flow.add(_link);
        _flow.add(_connectors);
        _flow.add(_dots);
        _events.forEach(function(event) {
            event.position = {x:_laneWidth * (event.level + 0.5),  y:event.slot * _slotHeight};
        });
        for(var id in _activities) {
            drawActivity(_activities[id]);
        };
        self.setScroll(_scroll, _contentHeight, _windowHeight);
    }

    function getEventById(id) {
        var event;
        _events.every(function (entry) {
            if(entry.id == id) {
                event = entry;
                return false;
            } else {
                return true;
            }
        });
        return event;
    }

    function transform(scale, target) {
        if(typeof(target) != "object") target = getEventById(target);
        if(target && target.display && (_event == undefined || _event.id != target.id)) {
            var transform = "s" + scale + " " + scale;
            target.display.attr({
                transform:transform
            });
        }
    }

    function drawLane(levels, x, y) {
        var height = (_timeSlots.length + 1) * _slotHeight;
        var lane = _svg.g();
        var strokeWidth = 1;
        var width = levels * _laneWidth;
        var rect;
        rect = _svg.rect(0, 0, width - strokeWidth, height);
        rect.attr({
            fill:_backgroundColor,
        });
        lane.add(rect);
        rect = _svg.rect(width - strokeWidth, 0, strokeWidth, height);
        rect.attr({
            fill:"#ffffff",
        });
        lane.add(rect);
        lane.attr({
            transform: "t" + x + " " + y
        });
       return lane;
    }

    function drawActivity(data) {
        var positions = [];
        var color = getActivityColor(data);
        var path, previous, commands, level, innerCircle, target, strokeWidth, rect, separator;
        data.events.forEach(function(event) {
            var current = event;
            if(previous != undefined) {
                for (var index = previous.slot; index < current.slot; index++) {
                    strokeWidth = _circleRadius * 2;
                    level = current.position.x;
                    commands  = "M" +  level + " " + (_slotHeight * index) + "L" + level + " " + (_slotHeight * (index + 1));
                    path = _svg.path(commands);
                    path.attr({
                        fill:"none",
                        stroke:color,
                        strokeLinecap:"round",
                        strokeWidth: strokeWidth,
                        pointerEvents:"none"
                    });
                    _lines.add(path);
                }
            }
            if(current.fromNode != undefined || current.fromActivity != undefined) {
                strokeWidth = _circleStroke;
                target = current.fromNode != undefined? getEventById(current.fromNode).position : {x:_activities[current.fromActivity].events[0].position.x, y:current.position.y - _slotHeight / 2};
                if(current.sync) {
                    rect = _svg.line.apply(_svg, patch(event));
                    rect.attr({
                        stroke:_backgroundColor,
                        strokeWidth:_circleRadius * 2 + 0.5,
                        opacity: 0.75,
                        pointerEvents:"none"
                    });
                    _lines.add(rect);
                }
                path = _svg.path(bind(target, current.position));
                path.attr({
                    fill:"none",
                    stroke:color,
                    strokeWidth: strokeWidth,
                    pointerEvents:"none"
                });
                _dots.add(path);
                if(current.fromNode != undefined) {
                    innerCircle = _svg.circle(target.x, target.y, _circleStroke);
                    innerCircle.attr({
                        fill:color,
                        pointerEvents:"none"
                    });
                    _dots.add(innerCircle);
                } else {
                    separator = _svg.line(target.x - _circleRadius, target.y + _circleStroke / 2, target.x + _circleRadius, target.y + _circleStroke / 2);
                    separator.attr({
                        stroke:color,
                        strokeWidth:_circleStroke,
                        pointerEvents:"none"
                    });
                    _dots.add(separator);
                }
            }
            if(event.toNode != undefined || event.toActivity != undefined) {
                strokeWidth = _circleStroke;
                target = current.toNode != undefined? getEventById(current.toNode).position : {x:_activities[current.toActivity].events[0].position.x, y:current.position.y + _slotHeight / 2};
                path = _svg.path(bind(current.position, target));
                path.attr({
                    fill:"none",
                    stroke:color,
                    strokeWidth: strokeWidth,
                    pointerEvents:"none"
                });
                _dots.add(path);
                if(current.toNode != undefined) {
                    innerCircle = _svg.circle(target.x, target.y, _circleStroke);
                    innerCircle.attr({
                        fill:color,
                        pointerEvents:"none"
                    });
                    _dots.add(innerCircle);
                } else {
                    separator = _svg.line(target.x - _circleRadius, target.y - _circleStroke / 2, target.x + _circleRadius, target.y - _circleStroke / 2);
                    separator.attr({
                        stroke:color,
                        strokeWidth:_circleStroke,
                        pointerEvents:"none"
                    });
                    _dots.add(separator);
                }
            }
            if(event.connect != undefined) {
                strokeWidth = _circleStroke / 2;
                target = getEventById(current.connect).position;
                path = _svg.path(call(current.position, target));
                path.attr({
                    fill:"none",
                    stroke:color,
                    strokeDasharray: [4,2],
                    strokeWidth: strokeWidth,
                    pointerEvents:"none"
                });
                _connectors.add(path);
                var size = 6;
                var direction = current.position.x > target.x? 1 : -1;
                var peak = {x:target.x + (_circleRadius + _circleStroke * 2) * direction, y:target.y};
                arrow = _svg.polyline([peak.x, peak.y, peak.x + size * direction, peak.y - size / 2, peak.x + size * direction, peak.y + size / 2]);
                arrow.attr({
                    fill:color,
                    pointerEvents:"none"
                });
                _connectors.add(arrow);
            }
            previous = current;
        });
        if(_event) {
            var selection = _svg.circle(_event.position.x, _event.position.y, _laneWidth / 2 - _circleStroke - 1);
            selection.attr({
                fill:"none",
                stroke: "#cccccc",
                strokeWidth: _circleStroke,
                pointerEvents:"none"
            });
            _selection.add(selection);
        }
        data.events.forEach(function(event) {
            var circle;
            switch(event.type) {
                case "start":
                    circle = _svg.circle(event.position.x, event.position.y, _circleRadius + _circleStroke);
                    circle.attr({
                        fill:color,
                        stroke:color,
                        strokeWidth:_circleStroke,
                        cursor: "pointer"
                    });
                    _dots.add(circle);
                    break;
                case "end":
                    circle = _svg.circle(event.position.x, event.position.y, _circleRadius + _circleStroke);
                    circle.attr({
                        fill:"#ffffff",
                        stroke:color,
                        strokeWidth:_circleStroke,
                        cursor: "pointer"
                    });
                    _dots.add(circle);
                    innerCircle = _svg.circle(event.position.x, event.position.y, _circleRadius - 1);
                    innerCircle.attr({
                        fill:color,
                        pointerEvents:"none"
                    });
                    _dots.add(innerCircle);
                    break;
                case "event":
                    circle = _svg.circle(event.position.x, event.position.y, _circleRadius + 1);
                    circle.attr({
                        fill:"#ffffff",
                        stroke:color,
                        strokeWidth:_circleStroke,
                        cursor: "pointer"
                    });
                    _dots.add(circle);
                    break;
            }
            circle.node.setAttribute("eventId", event.id);
            circle.mouseover(circleMouseOverHandler);
            circle.mouseout(circleMouseOutHandler);
            circle.click(circleClickHandler);
            event.display = circle;
        });
    }

    function bind(previous, current) {
        var jump = current.x -  previous.x;
        var commands = "M" + previous.x + " " + (previous.y + 0.5);
        var points;
        if(jump > 0) {
            points = [
                {x: previous.x, y: previous.y + _circleRadius},
                {x: previous.x + _curveRadius, y:previous.y + _circleRadius + _curveRadius},
                {x:current.x - _curveRadius, y:previous.y + _circleRadius + _curveRadius},
                {x:current.x, y: previous.y + _circleRadius + _curveRadius * 2}
            ];
        } else if(jump < 0) {
            points = [
                {x:previous.x, y:current.y - _circleRadius - _curveRadius * 2},
                {x:previous.x - _curveRadius, y:current.y - _circleRadius - _curveRadius},
                {x:current.x + _curveRadius, y:current.y - _circleRadius - _curveRadius},
                {x:current.x, y:current.y - _circleRadius}
            ];
        }
        if(points) {
            commands += "L" + points[0].x + " " + points[0].y;
            commands += "Q" + points[0].x + " " + points[1].y + " " + points[1].x + " " + points[1].y;
            commands += "L" + points[2].x + " " + points[2].y;
            commands += "Q" + points[3].x + " " + points[2].y + " " + points[3].x + " " + points[3].y;
        }
        commands +=  "L" + current.x + " " + (current.y - 0.5);
        return commands;
    }

    function call(previous, current) {
        var jump = current.x -  previous.x;
        var commands = "M" + previous.x + " " + previous.y;
        var points, side;
        if(jump > 0) {
            side = jump == _laneWidth? -1 : 1
            points = [
                {x:previous.x, y:previous.y},
                {x:previous.x + (_curveRadius + _circleRadius) * side, y:previous.y + _curveRadius},
                {x:previous.x + (_curveRadius + _circleRadius) * side, y:current.y - _curveRadius},
                {x:previous.x + (_curveRadius + _circleRadius) * side  + _curveRadius, y:current.y},
                {x:current.x - _circleRadius - _curveRadius, y:current.y}
            ];
        } else if(jump < 0) {
            side = jump == -_laneWidth? -1 : 1;
            points = [
                {x:previous.x, y:previous.y},
                {x:previous.x - (_curveRadius + _circleRadius) * side, y:previous.y + _curveRadius},
                {x:previous.x - (_curveRadius + _circleRadius) * side, y:current.y - _curveRadius},
                {x:previous.x - (_curveRadius + _circleRadius) * side - _curveRadius, y:current.y},
                {x:current.x + _circleRadius + _curveRadius, y:current.y}
            ];
        }
        if(points) {
            commands += "L" + points[0].x + " " + points[0].y;
            commands += "Q" + points[1].x + " " + points[0].y + " " + points[1].x + " " + points[1].y;
            commands += "L" + points[2].x + " " + points[2].y;
            commands += "Q" + points[2].x + " " + points[3].y + " " + points[3].x + " " + points[3].y;
            commands += "L" + points[4].x + " " + points[4].y;
        }
        return commands;
    }

    function patch(startEvent) {
        var activity = _activities[startEvent.activity];
        var parent = activity.parent;
        var endEvent = activity.events[activity.events.length - 1];
        var y1 = startEvent.fromNode != undefined? getEventById(startEvent.fromNode).slot * _slotHeight : (startEvent.fromActivity != undefined? startEvent.slot * _slotHeight - _slotHeight / 2 : parent.events[0].slot * _slotHeight );
        var y2 = endEvent.toNode != undefined? getEventById(endEvent.toNode).slot  * _slotHeight : (endEvent.toActivity != undefined? endEvent.slot  * _slotHeight + _slotHeight / 2 : parent.events[parent.events.length - 1].slot * _slotHeight );
        var x = (parent.events[0].level + 0.5) * _laneWidth;
        return [x, y1, x, y2]
    }

    function getActivityColor(activity) {
        var color = parseInt(activity.color.substring(1, Number.MAX_VALUE), 16);
        var background = parseInt(_backgroundColor.substring(1, Number.MAX_VALUE), 16);
        var disabled = _activity && _activity != activity;
        if(disabled) {
            while(activity.parent != undefined) {
                activity = activity.parent;
                if(_activity == activity) {
                    disabled = false;
                    break;
                }
            }
        }
        color = dim(color, disabled? 0.5 : 1);
        if(disabled) {
            color = greyScale(color);
            color = multiply(color, background);
        }
        color = color.toString(16);
        while(color.length < 6) {
            color = "0" + color;
        }
        return "#" + color;
    }

    function dim(color, alpha) {
        var r = (color & 0xff0000) >> 16;
        var g = (color & 0x00ff00) >> 8;
        var b = (color & 0x0000ff);
        r += (0xff - r) * (1 - alpha);
        g += (0xff - g) * (1 - alpha);
        b += (0xff - b) * (1 - alpha);
        return r << 16 | g << 8 | b;
    }

    function multiply(a, b) {
        var ar = (a & 0xff0000) >> 16;
        var ag = (a & 0x00ff00) >> 8;
        var ab = (a & 0x0000ff);
        var br = (b & 0xff0000) >> 16;
        var bg = (b & 0x00ff00) >> 8;
        var bb = (b & 0x0000ff);
        return Math.max(ar + br - 0xff, 0) << 16 | Math.max(ag + bg - 0xff, 0) << 8 | Math.max(ab + bb - 0xff, 0);
    }

    function greyScale(color, alpha) {
        var r = (color & 0xff0000) >> 16;
        var g = (color & 0x00ff00) >> 8;
        var b = (color & 0x0000ff);
        var l = .2126 * r + .7152 * g + .0722 * b;
        return l << 16 | l << 8 | l;
    }

    function circleMouseOverHandler(e) {
        var id = e.target.getAttribute("eventId");
        self.expand(id, e.target);
    }

    function circleMouseOutHandler(e) {
        var id = e.target.getAttribute("eventId");
        self.contract(id, e.target);
    }

    function circleClickHandler(e) {
        var id = e.target.getAttribute("eventId");
        self.dispatchEvent(new Event(Event.SELECT, getEventById(id)));
    }

    init(containerId);
}
