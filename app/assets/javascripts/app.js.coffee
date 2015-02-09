@app = angular.module('poirot', [])

@app.run ($rootScope) ->
  $rootScope.formatTimestamp = (ts) ->
    date = new Date(ts)
    h = date.getUTCHours()
    m = date.getUTCMinutes()
    s = date.getUTCSeconds()
    ms = date.getUTCMilliseconds()

    pad = (num, size) ->
      str = num + ""
      while str.length < size
        str = "0" + str
      str

    "#{date.toDateString()}, #{h}:#{pad m, 2}:#{pad s, 2}.#{pad ms, 3} UTC"

