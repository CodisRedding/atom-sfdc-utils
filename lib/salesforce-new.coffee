Salesforce = require './salesforce'
fs = require 'fs'
path = require 'path'

# [SalesforceNew]
# Handles creating new Salesforce components
module.exports =
class SalesforceNew extends Salesforce
  constructor: (@logView, @statusBar) ->
    super(@logView, @statusBar)

  createApexPage: (filePath, fullName, label, desc, callback) ->
    file = "#{path.join(filePath, fullName)}.page"

    # Already exists locally, update statusbar
    if fs.existsSync(file)
      @statusBar.setStatus "#{fullName} already exists locally"
      # fade out the current status bar value
      setTimeout (=>
        @statusBar.clear()
      ), 5000
      return

    self = @
    # Create a connection to Salesforce
    @login (err, res) ->
      return console.error err if err

      # max records to fetch is 5k
      records = []
      query = self.conn.query('SELECT Id FROM ApexPage WHERE Name = \'' + fullName + '\' LIMIT 1')
      query.on("record", (record) ->
        records.push record
        return
      ).on("error", (err) ->
        return console.error err if err
      ).on("end", ->
        if records.length == 0
          self._createFiles file, label, desc, callback
        else
          self.statusBar.setStatus "#{fullName} already exists on Salesforce"
        return
      ).run
        autoFetch: true
        maxFetch: 5000

      # fade out the current status bar value
      setTimeout (=>
        self.statusBar.clear()
      ), 5000
      return

  _createFiles: (file, label, desc, callback) ->
    try
      page = fs.readFileSync(path.join(__dirname, '../templates/apex.page'))
      meta = fs.readFileSync(path.join(__dirname, '../templates/apex.page.meta'))

      meta = meta.toString()
      meta = meta.replace('{API}', @getApiVersion())
      meta = meta.replace('{DESCRIPTION}', desc)
      meta = meta.replace('{LABEL}', label)

      fs.writeFileSync file, page
      fs.writeFileSync "#{file}-meta.xml", meta

      callback(null, file)
    catch error
      callback(error)
