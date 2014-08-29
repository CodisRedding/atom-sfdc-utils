{allowUnsafeEval, allowUnsafeNewFunction} = require 'loophole'
_ = require 'underscore'
utils = require './utils'
SalesforceDescribe = require './salesforce-describe'

$ = null
config = null
jsforce = null
SfdcUtilsProgressBarView = null
SfdcUtilsLogView = null

module.exports =
  sfdcUtilsProgressBarView: null
  sfdcUtilsLogView: null
  configDefaults:
    loginUrl: 'https://login.salesforce.com'
    username: null
    password: null
    securityToken: null
    apiVersion: 'xx.x'

  activate: (state) ->
    $ ?= require('atom').$
    allowUnsafeNewFunction ->
      jsforce ?= require 'jsforce'
    config ?= require './config/salesforce'
    SfdcUtilsProgressBarView ?= require './sfdc-utils-progressbar-view'
    SfdcUtilsLogView ?= require './sfdc-utils-log-view'
    @sfdcUtilsProgressBarView = new SfdcUtilsProgressBarView()
    @sfdcUtilsLogView = new SfdcUtilsLogView(state.sfdcUtilsLogViewState)

    # Hooking up commands
    atom.workspaceView.command 'sfdc-utils:toggle', =>
      console.debug 'sfdc-utils:toggle triggered'
      @toggle()
    atom.workspaceView.command 'sfdc-utils:closeLogView', =>
      console.debug 'sfdc-utils:closeLogView triggered'
      @closeLogView()
    atom.workspaceView.command 'sfdc-utils:getObjectPermissions', =>
      console.debug 'sfdc-utils:getPermsForSObject triggered'
      @getPermsForSObject()
    atom.workspaceView.command 'sfdc-utils:getFieldInfo', =>
      console.debug 'sfdc-utils:getFieldInfo triggered'
      @getFieldInfo()
    atom.workspaceView.command 'sfdc-utils:executeSoql', =>
      console.debug 'sfdc-utils:executeSoql triggered'
      @executeSoql()
    atom.workspaceView.command 'sfdc-utils:saveMetaComponents', =>
      console.debug 'sfdc-utils:saveMetaComponents triggered'
      @saveMetaComponents()

    self = @

  deactivate: ->
    #@sfdcUtilsView.destroy()
    @sfdcUtilsProgressBarView?.destroy()
    @sfdcUtilsLogView?.destroy()

  serialize: ->
    #sfdcUtilsViewState: @sfdcUtilsView.serialize()
    sfdcUtilsLogViewState: @sfdcUtilsLogView?.serialize()

  #
  # Clear status after interval
  #
  clearStatusBar: ->
    setTimeout (=>
      @sfdcUtilsProgressBarView.clear()
    ), 5000

  closeLogView: ->
    @sfdcUtilsLogView?.destroy()

  #
  # Show/hide the retreive log
  #
  toggle: ->
    @sfdcUtilsLogView.toggle()

  getFieldInfo: ->
    editor = atom.workspace.activePaneItem
    selection = editor.getSelection()
    parts = selection.getText().trim().split('.')
    sobject = parts[0]
    field = parts[1]
    conn = new jsforce.Connection()
    self = @

    allowUnsafeNewFunction ->
      conn.login config.username,
        config.password + config.securityToken, (err, res) ->
          return console.error(err) if err
          describe = new SalesforceDescribe(conn, self.sfdcUtilsLogView,
            self.sfdcUtilsProgressBarView)
          describe.describeField sobject, field

  executeSoql: ->
    editor = atom.workspace.activePaneItem
    selection = editor.getSelection()
    conn = new jsforce.Connection()

    @sfdcUtilsProgressBarView.setStatus 'Retrieving...'
    self = @
    allowUnsafeNewFunction ->
      conn.login config.username, config.password + config.securityToken, (err, res) ->
        return console.error(err) if err

        records = []
        query = conn.query(selection.getText().trim())
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
          self.sfdcUtilsLogView.show()
          self.sfdcUtilsLogView.clear()
          self.sfdcUtilsLogView.print err.toString(), true if err
          return console.error err if err
          self.sfdcUtilsLogView.removeLastEmptyLogLine()
          printHeaders = true
          getKey = true
          table = ''
          headers = ''
          row = ''
          linkleft = ''
          linkright = ''
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
                row += "<td nowrap>&nbsp;#{linkleft}#{utils.colorify2(val[key])}#{linkright}&nbsp;</td>"
            )
          table += "<tr>#{row}</tr>"
          )
          self.sfdcUtilsLogView.print "<table>#{table}</table>", false
          self.sfdcUtilsProgressBarView.setStatus 'Finished'
          self.clearStatusBar()
          return
        )

  saveMetaComponents: ->
    @sfdcUtilsProgressBarView.setStatus 'Saving...'
    conn = new jsforce.Connection()
    editor = atom.workspace.getActiveEditor()
    editor.save()
    parts = editor.getTitle().split('.')
    fullName = parts[0]

    if parts.length > 2
      fileExt = ".#{parts[parts.length - 2]}.#{parts[parts.length - 1]}"
    else
      fileExt = ".#{parts[parts.length - 1]}"

    isMeta = fileExt.contains('-meta.xml')
    ext = null
    meta = null
    exts = [
            [".cls", "ApexClass"]
            [".page", "ApexPage"]
            [".trigger", "ApexTrigger"]
            [".component", "ApexComponent"]
            [".object", "CustomObject"]
            [".cls-meta.xml", "ApexClass"]
            [".page-meta.xml", "ApexPage"]
            [".trigger-meta.xml", "ApexTrigger"]
            [".component-meta.xml", "ApexComponent"]
          ]

    _.each(exts, (v, k) ->
      if v[0] is fileExt
        ext = v[0]
        meta = v[1]
    )

    if ext = null
      #not a force.com file
      @sfdcUtilsProgressBarView.setStatus 'Finished'
      @clearStatusBar()
      return

    @sfdcUtilsProgressBarView.setStatus 'Packaging metadata...'

    fs = null
    xpath = null
    dom = null
    metadata = null

    console.debug 'meta: %s', meta
    switch meta
      when 'ApexPage'
        if isMeta
          fs ?= require 'fs'
          xpath ?= require 'xpath'
          dom ?= require('xmldom').DOMParser
          xml = fs.readFileSync(editor.getPath()).toString()
          xml = xml.replace(' xmlns="http://soap.sforce.com/2006/04/metadata"', '')
          doc = new dom().parseFromString(xml)
          ver = xpath.select("//apiVersion/text()", doc).toString()
          desc = xpath.select("//description/text()", doc).toString()
          label = xpath.select("//label/text()", doc).toString()
          fullName = xpath.select("//fullName/text()", doc).toString()
          metadata = [{
              apiVersion: ver
              content: Buffer(fs.readFileSync(editor.getPath().replace(meta, ''))).toString('base64')
          }]
          metadata[0].fullName = fullName if fullName
          metadata[0].label = label if label
          console.debug 'metadata: %s', JSON.stringify(metadata)
          allowUnsafeNewFunction ->
            conn.login config.username, config.password + config.securityToken, (err, res) ->
              conn.tooling.getMetadataContainerId((res) ->
                if res.size = 1
                  console.debug 'Id: %s', res.records[0].Id)
          return
        elseSr.
          fs ?= require 'fs'
          metadata = [{
              apiVersion: config.apiVersion
              content: Buffer(fs.rea dFileSync(editor.getPath())).toString('base64')
              fullName: fullName
              label: fullName
          }]

    self = @
    allowUnsafeNewFunction ->
      conn.login config.username, config.password + config.securityToken, (err, res) ->
        return console.error(err) if err

        conn.metadata.upsertAsync('ApexPage', metadata, (err, res) ->
          return console.error(err) if err
          console.debug 'res: %s', res.success

          if res.success
            self.sfdcUtilsProgressBarView.setStatus "#{res.fullName} saved to server"
          else
            self.sfdcUtilsLogView.show()
            self.sfdcUtilsLogView.clear()
            self.sfdcUtilsProgressBarView.setStatus "Error saving to server"
            self.sfdcUtilsLogView.print err, true if err
            self.sfdcUtilsLogView.print "Error<br />#{JSON.stringify(res.errors, null, 2).replace(/\\/g, '')}" , true
        )

    @clearStatusBar()

    # file title
    #editor.coffee
    #getTite()
    #@getPath()
    #getText()
    #require path
    #path.dirname(@getPath() + '-meta.xml')


  getPermsForSObject: ->
    editor = atom.workspace.activePaneItem
    selection = editor.getSelection()
    parts = selection.getText().trim().split('.')
    sobject = parts[0]
    field = parts[1]
    conn = new jsforce.Connection()

    @sfdcUtilsProgressBarView.setStatus 'Retrieving...'
    self = @
    allowUnsafeNewFunction ->
      conn.login config.username, config.password + config.securityToken, (err, res) ->
        return console.error(err) if err

        query = ''
        if field
          query = "SELECT Id, Field, PermissionsEdit, PermissionsRead,
                      Parent.Profile.Name
                      FROM FieldPermissions
                      WHERE SobjectType = '#{sobject}' AND Field =
                      '#{selection.getText().trim()}'
                      ORDER BY Parent.Profile.Name"
        else
          query = "SELECT Id, SobjectType, PermissionsCreate, PermissionsDelete,
                      PermissionsEdit, PermissionsModifyAllRecords, PermissionsRead,
                      PermissionsViewAllRecords, Parent.ProfileId, Parent.Profile.Name
                      FROM ObjectPermissions
                      WHERE SobjectType = '#{sobject}' ORDER BY Parent.Profile.Name"

        conn.query query, (err, res) ->
          self.sfdcUtilsLogView.show()
          self.sfdcUtilsLogView.clear()
          self.sfdcUtilsLogView.removeLastEmptyLogLine()

          if err
            self.sfdcUtilsLogView.print err.toString(), true
            self.sfdcUtilsProgressBarView.setStatus 'Failed'
            self.clearStatusBar()
            return

          _.each(res.records, (val, key) ->
            msg = ''
            if field
              msg = val.Parent.Profile.Name + " (" + val.Field + " " + "
                permissions)<br />&nbsp;&nbsp;&nbsp;&nbsp;
                read: " + utils.colorify(val.PermissionsRead) + " " + "
                edit: " + utils.colorify(val.PermissionsEdit)
            else
              msg = val.Parent.Profile.Name + " (" + val.SobjectType + " " + "
                permissions)<br />&nbsp;&nbsp;&nbsp;&nbsp;
                create: " + utils.colorify(val.PermissionsCreate) + " " + "
                read: " + utils.colorify(val.PermissionsRead) + " " + "
                edit: " + utils.colorify(val.PermissionsEdit) + " " + "
                delete: " + utils.colorify(val.PermissionsDelete) + " " + "
                view all: " + utils.colorify(val.PermissionsViewAllRecords) + " " + "
                modify all: " + utils.colorify(val.PermissionsModifyAllRecords)
            self.sfdcUtilsLogView.print msg, false)

          self.sfdcUtilsProgressBarView.setStatus 'Finished'
          self.clearStatusBar()
          return

        return
