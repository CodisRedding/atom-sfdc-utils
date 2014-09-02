SalesforceDescribe = require './salesforce-describe'
SalesforceSoql = require './salesforce-soql'
SalesforcePermissions = require './salesforce-permissions'
SalesforceMeta = require './salesforce-meta'
SalesforceNew = require './salesforce-new'
path = require 'path'

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
    SfdcUtilsProgressBarView ?= require './sfdc-utils-progressbar-view'
    SfdcUtilsLogView ?= require './sfdc-utils-log-view'
    @sfdcUtilsProgressBarView = new SfdcUtilsProgressBarView()
    @sfdcUtilsLogView = new SfdcUtilsLogView(state.sfdcUtilsLogViewState)

    # Hooking up commands
    atom.workspaceView.command 'sfdc-utils:toggle', =>
      @toggle()
    atom.workspaceView.command 'sfdc-utils:closeLogView', =>
      @closeLogView()
    atom.workspaceView.command 'sfdc-utils:getObjectPermissions', =>
      @getPermsForSObject()
    atom.workspaceView.command 'sfdc-utils:getFieldInfo', =>
      @getFieldInfo()
    atom.workspaceView.command 'sfdc-utils:executeSoql', =>
      @executeSoql()
    atom.workspaceView.command 'sfdc-utils:saveMetaComponents', =>
      @saveMetaComponents()
    atom.workspaceView.command 'sfdc-utils:createNewComponent', =>
      @createNewComponent()

    self = @

  deactivate: ->
    @sfdcUtilsProgressBarView?.destroy()
    @sfdcUtilsLogView?.destroy()

  serialize: ->
    sfdcUtilsLogViewState: @sfdcUtilsLogView?.serialize()

  closeLogView: ->
    @sfdcUtilsLogView?.toggle()

  toggle: ->
    @sfdcUtilsLogView.toggle()


  saveMetaComponents: ->
    editor = atom.workspace.getActiveEditor()
    editor.save()
    path = editor.getPath()

    meta = new SalesforceMeta(path, @sfdcUtilsLogView,
                    @sfdcUtilsProgressBarView)

    meta.save()

  createNewComponent: ->
    editor = atom.workspace.getActiveEditor()
    filePath = editor.getPath()
    selection = editor.getSelection()
    parts = selection.getText().trim().split('.')
    return if parts.length < 3

    [type, name, label] = [parts[0], parts[1], parts[2]]
    desc = if parts.length == 4 then parts[3] else ''

    sfNew = new SalesforceNew(@sfdcUtilsLogView,
                    @sfdcUtilsProgressBarView)

    dirName = path.dirname(filePath)
    self = @

    if type == 'ApexPage'
      sfNew.createApexPage dirName, name, label, desc, (err, res) ->
        return console.error(err) if err

        page = res # page path
        meta = new SalesforceMeta(page, self.sfdcUtilsLogView,
                        self.sfdcUtilsProgressBarView)
        meta.save()

    else if type == 'ApexTrigger'
      # TODO
      return null
      
    else if type == 'ApexClass'
      # TODO
      return null


  # Displays describe information about a sobject
  # field. This information includes picklist
  # values
  getFieldInfo: ->
    editor = atom.workspace.activePaneItem
    selection = editor.getSelection()
    parts = selection.getText().trim().split('.')
    [sobject, field] = [parts[0], parts[1]]

    describe = new SalesforceDescribe(@sfdcUtilsLogView,
                    @sfdcUtilsProgressBarView)

    describe.describeField sobject, field

  # Displays the results of the soql passed in
  executeSoql: ->
    editor = atom.workspace.activePaneItem
    query = editor.getSelection().getText().trim()
    soql = new SalesforceSoql(@sfdcUtilsLogView,
                @sfdcUtilsProgressBarView)

    soql.executeSoql query

  # Displays the permissions for a sobject
  # or field for every profile
  getPermsForSObject: ->
    editor = atom.workspace.activePaneItem
    selection = editor.getSelection()
    parts = selection.getText().trim().split('.')
    [sobject, field] = [parts[0], parts[1]]

    perms = new SalesforcePermissions(@sfdcUtilsLogView,
      @sfdcUtilsProgressBarView)

    if field
      perms.getFieldPermissions sobject, field
    else if sobject
      perms.getSobjectPermissions sobject
