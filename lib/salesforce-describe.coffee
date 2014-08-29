Salesforce = require './salesforce'

module.exports =
class SalesforceDescribe extends Salesforce
  constructor: (@logView, @statusBar) ->
    super(@logView, @statusBar)

  describeField: (sobjectName, field) ->
    un = @config.username
    pw = @config.password + @config.securityToken
    conn = new jsforce.Connection()
    self = @

    conn.login un, pw, (err, res) ->
      return console.error err if err

      sobj = conn.sobject(sobjectName)
      self.statusBar.setStatus 'Retrieving...'
      sobj.describe().done((res, err) ->
        self.logView.print err.toString(), true if err
        return console.error err if err

        found = false
        res.fields.forEach((fld) ->
          if fld.name is field
            found = true
            self.logView.show()
            self.logView.clear()
            self.logView.removeLastEmptyLogLine()

            plist = ''
            fld.picklistValues.forEach((plistVal) ->
              if plistVal.active
                plist += "<br />#{self.pad('')}
                  #{if plistVal.defaultValue then '[default] -> ' else ''}
                  #{utils.colorify2(plistVal.value)}"
            )

            # if the field is a picklist
            # display the formatted picklist values
            self.logView.print self.print(k,
              if k is 'picklistValues' then plist else v) for k, v of fld
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

  print: (key, value) ->
    return @pad("#{key}: #{value}")

  pad: (output) ->
    return "&nbsp;&nbsp;&nbsp;#{output}"
