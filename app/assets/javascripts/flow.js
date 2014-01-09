function Flow(containerId) {

    var SERVER_ICON = "M0,0v2.995h16.031V0H0z M1.519,2.187c-0.406,0-0.735-0.329-0.735-0.735c0-0.406,0.329-0.735,0.735-0.735c0.406,0,0.735,0.329,0.735,0.735C2.254,1.858,1.924,2.187,1.519,2.187z M0,6.995h16.031V4H0V6.995z M1.519,4.717c0.406,0,0.735,0.329,0.735,0.735c0,0.406-0.329,0.735-0.735,0.735c-0.406,0-0.735-0.329-0.735-0.735C0.784,5.046,1.113,4.717,1.519,4.717z M0,10.995h7.005v1.266C6.702,12.44,6.454,12.694,6.28,13H0v1.981h6.285c0.347,0.604,0.99,1.015,1.736,1.015s1.39-0.411,1.736-1.015h6.273V13H9.762c-0.18-0.317-0.44-0.577-0.757-0.756v-1.249h7.026V8H0V10.995z M1.519,8.717c0.406,0,0.735,0.329,0.735,0.735c0,0.406-0.329,0.735-0.735,0.735c-0.406,0-0.735-0.329-0.735-0.735C0.784,9.046,1.113,8.717,1.519,8.717z";

    var _container = document.getElementById(containerId);
    var _svg = Snap("#" + containerId);
    var _self = this;
    var _height = 0;
    var _width = 0;
    var _laneWidth = 25;
    var _slotHeight = 20;
    var _interval = [];
    var _lanes = [];
    var _levels = [];
    var _activities = [];

    _self.render = function() {
        resetInterval();
        _svg.clear();
        var boundingBox = {x:0, y:0, width:0, height:0};
        for (var i = _lanes.length - 1; i >= 0; i--) {
            var lane = _lanes[i];
            boundingBox = drawLane(lane.length, boundingBox.x + boundingBox.width, 0, _height).getBBox();
        };
        _width = boundingBox.x + boundingBox.width;
        _container.setAttribute("width", _width + "px");
        _activities.forEach(function(activity) {
            drawActivity(activity);
        });
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
        for (var i = data.activities.length - 1; i >= 0; i--) {
            var activity = data.activities[i];
            _activities[activity.id] = {id:activity.id, color:activity.color, events:[]};
        };
        for (i = data.events.length - 1; i >= 0; i--) {
            var event = data.events[i];
            activity = _activities[event.activity];
            activity.events.push({id:event.id,time:event.time,lane:event.lane, level:_levels[event.lane]});
        };
        
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
                stroke:"#bcbcbc",
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
        var icon = _svg.path(SERVER_ICON);
        icon.attr({
            fill:"#999999",
            transform: "t" + 4 + " " + 4
        });
        lane.add(icon);
        lane.attr({
            transform: "t" + x + " " + y
        });
       return lane;
    }

    function drawActivity(activity) {
        var positions = [];
            var commands = "M";
            var last_event;
            activity.events.forEach(function(event) {
                event.position = {x:_laneWidth * (event.level + 0.5),  y:event.time * _slotHeight + 30};
                if(commands != "M") {
                    var jump = last_event.level - event.level;
                    if(jump) {
                        var pivot = (last_event.position.y + event.position.y) / 2;
                        var radius = pivot - last_event.position.y;
                        if(jump > 0) {
                            commands += "Q" + last_event.position.x + " " + (last_event.position.y + radius) + " " + (last_event.position.x + radius) + " " + (last_event.position.y + radius);
                            commands += "L" + (event.position.x - radius) + " " + (event.position.y - radius);
                            commands += "Q" + event.position.x + " " + (event.position.y - radius) + " ";
                        } else {
                            commands += "Q" + last_event.position.x + " " + (last_event.position.y + radius) + " " + (last_event.position.x - radius) + " " + (last_event.position.y + radius);
                            commands += "L" + (event.position.x + radius) + " " + (event.position.y - radius);
                            commands += "Q" + event.position.x + " " + (event.position.y - radius) + " ";
                        }
                    } else {
                        commands += "L";
                    }
                }
                commands += event.position.x + " " + event.position.y;
                last_event = event;
            });
            var path = _svg.path(commands);
            path.attr({
                fill:"none",
                stroke:activity.color,
                strokeWidth:4,
            });
           activity.events.forEach(function(event) {
                radius = 3;
                var circle = _svg.circle(event.position.x, event.position.y, radius);
                circle.attr({
                    fill:"#ffffff",
                    stroke:activity.color,
                    strokeWidth:2,
                    cursor: "pointer",
                });
                circle.eventId = event.id;
                circle.mouseover(circleMouseOverHandler);
                circle.mouseout(circleMouseOutHandler);
                circle.click(circleClickHandler);
                event.shape = circle;
            });
    }

    function circleMouseOverHandler(e) {
        this.attr({
            strokeWidth:4,
            r:5
        });
    }

    function circleMouseOutHandler(e) {
        this.attr({
            strokeWidth:2,
            r:3
        });
    }

    function circleClickHandler(e) {
        if (_self.clickHandler) {
            _self.clickHandler(this.eventId);
        } else {
            alert("Event selected (id: " + this.eventId + ")");
        }
    }

    invalidate();
}
            
