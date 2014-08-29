{allowUnsafeEval, allowUnsafeNewFunction} = require 'loophole'
_ = require 'underscore'
utils = require './utils'
SalesforceDescribe = require './salesforce-describe'
SalesforceSoql = require './salesforce-soql'
SalesforcePermissions = require './salesforce-permissions'

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
    @sfdcUtilsProgressBarView?.destroy()
    @sfdcUtilsLogView?.destroy()

  serialize: ->
    sfdcUtilsLogViewState: @sfdcUtilsLogView?.serialize()

  #
  # Clear status after interval
  #
  clearStatusBar: ->
    setTimeout (=>
      @sfdcUtilsProgressBarView.clear()
    ), 5000

  closeLogView: ->
    @sfdcUtilsLogView?.hide()

  #
  # Show/hide the retreive log
  #
  toggle: ->
    @sfdcUtilsLogView.toggle()

  getFieldInfo: ->
    editor = atom.workspace.activePaneItem
    selection = editor.getSelection()
    parts = selection.getText().trim().split('.')
    [sobject, field] = [parts[0], parts[1]]
    describe = new SalesforceDescribe(@sfdcUtilsLogView,
                    @sfdcUtilsProgressBarView)

    describe.describeField sobject, field

  executeSoql: ->
    editor = atom.workspace.activePaneItem
    query = editor.getSelection().getText().trim()
    soql = new SalesforceSoql(@sfdcUtilsLogView,
                @sfdcUtilsProgressBarView)

    soql.executeSoql query

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

  getPermsForSObject: ->
    editor = atom.workspace.activePaneItem
    selection = editor.getSelection()
    parts = selection.getText().trim().split('.')
    sobject = parts[0]
    field = parts[1]

    perms = new SalesforcePermissions(@sfdcUtilsLogView,
      @sfdcUtilsProgressBarView)

    if field
      console.debug 'field'
      perms.getFieldPermissions sobject, field
    else if sobject
      console.debug 'sobject'
      perms.getSobjectPermissions sobject
