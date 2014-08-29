utils = require './utils'

module.exports =
class SalesforceDescribe
  constructor: (@conn, @logView, @statusBar) ->

  describeField: (sobjectName, field) ->
    sobj = @conn.sobject(sobjectName)

    @statusBar.setStatus 'Retrieving...'
    self = @
    sobj.describe().done((res, err) ->
      self.logView.print err.toString(), true if err
      return console.error(err) if err

      found = false
      res.fields.forEach((fld) ->
        if fld.name is field
          found = true
          self.logView.show()
          self.logView.clear()
          self.logView.removeLastEmptyLogLine()

          plistVals = ''
          fld.picklistValues.forEach((plistVal) ->
            if plistVal.active
              plistVals += pad("") + "
                #{if plistVal.defaultValue then '[default] -> ' else ''}
                #{utils.colorify2(plistVal.value)}"
            )

          self.logView.print self.pad("#{k}: #{v}") for k, v of fld
        )

      if found
        self.statusBar.setStatus 'Finished'
      else
        self.statusBar.setStatus "Couldn't find #{sobjectName}.#{field}", true
    )

    setTimeout (=>
      self.statusBar.clear()
    ), 5000

    return

  pad: (output) ->
    return "&nbsp;&nbsp;&nbsp;#{output}"
