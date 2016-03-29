@app.filter('attributeFilter', () ->
  (filter) ->

    if filter.type == 'range'
      filter.attr.displayName + ': ' + (filter.range.from || '-∞') + ' - ' + (filter.range.to || '∞')
    else
      filter.attr.displayName + ': ' + filter.value
)
