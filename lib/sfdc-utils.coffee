{allowUnsafeEval, allowUnsafeNewFunction} = require 'loophole'
_ = require 'underscore'

$ = null
config = null
jsforce = null
SfdcUtilsProgressBarView = null
SfdcUtilsLogView = null

module.exports =
  sfdcUtilsProgressBarView: null
  sfdcUtilsLogView: null
  configDefaults:
    loginUrl: "https://login.salesforce.com"
    username: null
    password: null
    securityToken: null

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

  colorify: (boolValue) ->
    if boolValue
      return '<font color="green">true</font>'
    else
      return '<font color="red">false</font>'

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
                  read: " + self.colorify(val.PermissionsRead) + " " + "
                  edit: " + self.colorify(val.PermissionsEdit)
              else
                msg = val.Parent.Profile.Name + " (" + val.SobjectType + " " + "
                  permissions)<br />&nbsp;&nbsp;&nbsp;&nbsp;
                  create: " + self.colorify(val.PermissionsCreate) + " " + "
                  read: " + self.colorify(val.PermissionsRead) + " " + "
                  edit: " + self.colorify(val.PermissionsEdit) + " " + "
                  delete: " + self.colorify(val.PermissionsDelete) + " " + "
                  view all: " + self.colorify(val.PermissionsViewAllRecords) + " " + "
                  modify all: " + self.colorify(val.PermissionsModifyAllRecords)
              self.sfdcUtilsLogView.print msg, false)

          self.sfdcUtilsProgressBarView.setStatus 'Finished'
          self.clearStatusBar()
          return

        return
