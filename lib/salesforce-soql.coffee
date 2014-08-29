Salesforce = require './salesforce'

module.exports =
class SalesforceSoql extends Salesforce
  constructor: (@logView, @statusBar) ->
    super(@logView, @statusBar)

  executeSoql: (soql) ->
    un = @config.username
    pw = @config.password + @config.securityToken
    conn = new jsforce.Connection()
    self = @

    conn.login un, pw, (err, res) ->
      return console.error err if err

      records = []
      query = conn.query(soql)
      query.on("record", (record) ->
        records.push record
        return
      ).on("error", (err) ->
        callback err
        return
      ).on("end", ->
        callback null,
          query: query
          records: records
        return
      ).run
        autoFetch: true
        maxFetch: 5000

      callback = ((err, result) ->
        self.logView.show()
        self.logView.clear()
        self.logView.print err.toString(), true if err
        return console.error err if err
        self.logView.removeLastEmptyLogLine()
        printHeaders = true
        getKey = true
        headers = ''
        linkleft = ''
        linkright = ''
        row = ''
        table = ""
        result.records.forEach((val, idx) ->
          if printHeaders
            printHeaders = false

            Object.keys(val).forEach((key) ->
              if key isnt 'attributes'
                headers += "<th nowrap>&nbsp;<strong>#{key}<strong>&nbsp;</th>"
            )
            table += "<tr>#{headers}</tr>"

          row = ''
          Object.keys(val).forEach((key) ->
            if val['Id']
              linkleft = "<a href=\"#{conn.loginUrl}/#{val['Id']}\">"
              linkright = '</a>'

            if key isnt 'attributes'
              row += "<td nowrap>&nbsp;#{linkleft}
                      #{self.utils.colorify2(val[key])}#{linkright}&nbsp;</td>"
          )

          table += "<tr>#{row}</tr>"
        )

        self.logView.print "<table>#{table}</table>", false
        self.statusBar.setStatus 'Finished'

        setTimeout (=>
          self.statusBar.clear()
        ), 5000
        return
      )
