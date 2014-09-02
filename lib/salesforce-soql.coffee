Salesforce = require './salesforce'

# [SalesforceSoql]
# Displays the results of a soql query
module.exports =
class SalesforceSoql extends Salesforce
  constructor: (@logView, @statusBar) ->
    super(@logView, @statusBar)

  # [executeSoql]
  # Displays the results of the soql passed in
  executeSoql: (soql, cb) ->
    self = @

    # Create a connection to Salesforce
    @login (err, res) ->
      return console.error err if err

      # max records to fetch is 5k
      records = []
      query = self.conn.query(soql)
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

      # Formats soql results
      callback = (err, result) ->
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

        result.records.forEach (val, idx) ->
          if printHeaders
            printHeaders = false

            # Create the soql results header
            Object.keys(val).forEach (key) ->
              if key isnt 'attributes'
                headers += "<th nowrap>&nbsp;<strong>#{key}<strong>&nbsp;</th>"

            table += "<tr>#{headers}</tr>"

          # Create the rows of data from soql results
          row = ''
          Object.keys(val).forEach (key) ->
            if val['Id']
              linkleft = "<a href=\"#{self.conn.loginUrl}/#{val['Id']}\">"
              linkright = '</a>'

            if key isnt 'attributes'
              row += "<td nowrap>&nbsp;#{linkleft}
                      #{self.utils.colorify2(val[key])}#{linkright}&nbsp;</td>"

          table += "<tr>#{row}</tr>"

        # Display formatted soql results
        self.logView.print "<table>#{table}</table>", false
        self.statusBar.setStatus 'Finished'

        # fade out the current status bar value
        setTimeout (=>
          self.statusBar.clear()
        ), 5000
        return
