function EventDispatcher() {

	var _self = this;
	var _listeners = [];

	_self.addEventListener = function(type, listener) {
		if(_listeners[type] == undefined) {
			_listeners[type] = [];
		}
		if(_listeners[type].indexOf(listener) == -1) {
			_listeners[type].push(listener);
		}
	}

	_self.removeEventListener = function(type, listener) {
		if(_listeners[type] != undefined) {
			var index = _listeners[type].indexOf(listener);
			if (index != -1) {
			    _listeners[type].splice(index, 1);
			}
		}
	}

	_self.willTrigger = function(type, listener) {
		var willTrigger = false;
		if(_listeners[type] != undefined) {
			var index = _listeners[type].indexOf(listener);
			willTrigger = index != -1;
		}
		return willTrigger;
	}

	_self.hasEventListener = function(type) {
		var hasEventListener = false;
		if(_listeners[type] != undefined) {
			hasEventListener = _listeners[type].length > 0;
		}
		return hasEventListener;
	}

	_self.dispatchEvent = function(event) {
		event.target = this;
		if(_listeners[event.type] != undefined) {
			_listeners[event.type].forEach(function(entry) {
				entry(event);
			});
		}
	}
}

function Event(type, info) {
	this.type = type;
	this.info = info;
}

Event.SELECT = "select";