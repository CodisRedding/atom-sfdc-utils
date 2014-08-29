SalesforceDescribe = require './salesforce-describe'
SalesforceSoql = require './salesforce-soql'
SalesforcePermissions = require './salesforce-permissions'

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

  closeLogView: ->
    @sfdcUtilsLogView?.toggle()

  toggle: ->
    @sfdcUtilsLogView.toggle()

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
