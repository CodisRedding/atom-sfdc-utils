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
    atom.workspaceView.command 'sfdc-utils:getFieldInfo', =>
      console.debug 'sfdc-utils:getFieldInfo triggered'
      @getFieldInfo()
    atom.workspaceView.command 'sfdc-utils:executeSoql', =>
      console.debug 'sfdc-utils:executeSoql triggered'
      @executeSoql()

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

  colorify2: (val, bool = true) ->
    return "<font color=\"" + (if bool then 'green' else 'red') + "\">#{val}</font>"

  getFieldInfo: ->
    # TODO
    editor = atom.workspace.activePaneItem
    selection = editor.getSelection()
    parts = selection.getText().trim().split('.')
    sobject = parts[0]
    field = parts[1]
    conn = new jsforce.Connection()
    foundDescribe = false

    @sfdcUtilsProgressBarView.setStatus 'Retrieving...'
    self = @
    allowUnsafeNewFunction ->
      conn.login config.username, config.password + config.securityToken, (err, res) ->
        return console.error(err) if err
        obj = conn.sobject(sobject)

        obj.describe().done((res, err) ->
            self.sfdcUtilsLogView.print err.toString(), true if err
            return console.error(err) if err

            res.fields.forEach((val, idx, arr) ->
                if val.name is field
                  foundDescribe = true
                  console.debug 'foundDescribe: %s', foundDescribe
                  self.sfdcUtilsLogView.show()
                  self.sfdcUtilsLogView.clear()
                  self.sfdcUtilsLogView.removeLastEmptyLogLine()

                  pvals = ''
                  val.picklistValues.forEach((pval) ->
                      if pval.active
                        pvals += "<br />&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;" +
                                  (if pval.defaultValue then '[default] -> ' else '') +
                                  "#{self.colorify2(pval.value)}"
                    )

                  self.sfdcUtilsLogView.print selection.getText().trim() + "
                    <br />&nbsp;&nbsp;&nbsp;Relationship Name: #{self.colorify2(val.relationshipName, true)}
                    <br />&nbsp;&nbsp;&nbsp;Auto Number: #{self.colorify(val.autoNumber)}
                    <br />&nbsp;&nbsp;&nbsp;Byte Length: #{self.colorify2(val.byteLength)}
                    <br />&nbsp;&nbsp;&nbsp;Calculated: #{self.colorify(val.calculated)}
                    <br />&nbsp;&nbsp;&nbsp;Calculated Formula: #{self.colorify2(val.calculatedFormula)}
                    <br />&nbsp;&nbsp;&nbsp;Cascade Delete: #{self.colorify(val.cascadeDelete)}
                    <br />&nbsp;&nbsp;&nbsp;Case Sensitive: #{self.colorify(val.caseSensitive)}
                    <br />&nbsp;&nbsp;&nbsp;Controller Name: #{self.colorify2(val.controllerName)}
                    <br />&nbsp;&nbsp;&nbsp;Createable: #{self.colorify(val.createable)}
                    <br />&nbsp;&nbsp;&nbsp;Custom: #{self.colorify(val.custom)}
                    <br />&nbsp;&nbsp;&nbsp;Default Value Formula: #{self.colorify2(val.defaultValueFormula)}
                    <br />&nbsp;&nbsp;&nbsp;Defaulted on Create: #{self.colorify(val.defaultedOnCreate)}
                    <br />&nbsp;&nbsp;&nbsp;Dependent Picklist: #{self.colorify(val.dependentPicklist)}
                    <br />&nbsp;&nbsp;&nbsp;Deprecated and Hidden: #{self.colorify(val.deprecatedAndHidden)}
                    <br />&nbsp;&nbsp;&nbsp;Digits: #{self.colorify2(val.digits)}
                    <br />&nbsp;&nbsp;&nbsp;Display Location In Decimal: #{self.colorify(val.displayLocationInDecimal)}
                    <br />&nbsp;&nbsp;&nbsp;External Id: #{self.colorify(val.externalId)}
                    <br />&nbsp;&nbsp;&nbsp;Extra Type Info: #{self.colorify2(val.extraTypeInfo)}
                    <br />&nbsp;&nbsp;&nbsp;Filterable: #{self.colorify(val.filterable)}
                    <br />&nbsp;&nbsp;&nbsp;Groupable: #{self.colorify(val.groupable)}
                    <br />&nbsp;&nbsp;&nbsp;HTML Formatted: #{self.colorify(val.htmlFormatted)}
                    <br />&nbsp;&nbsp;&nbsp;Id Lookup: #{self.colorify(val.idLookup)}
                    <br />&nbsp;&nbsp;&nbsp;Inline Help Text: #{self.colorify2(val.inlineHelpText)}
                    <br />&nbsp;&nbsp;&nbsp;Label: #{self.colorify2(val.label)}
                    <br />&nbsp;&nbsp;&nbsp;Length: #{self.colorify2(val.length)}
                    <br />&nbsp;&nbsp;&nbsp;Mask: #{self.colorify2(val.mask)}
                    <br />&nbsp;&nbsp;&nbsp;Mask Type: #{self.colorify2(val.maskType)}
                    <br />&nbsp;&nbsp;&nbsp;Name Field: #{self.colorify(val.nameField)}
                    <br />&nbsp;&nbsp;&nbsp;Name Pointing: #{self.colorify(val.namePointing)}
                    <br />&nbsp;&nbsp;&nbsp;Nillable: #{self.colorify(val.nillable)}
                    <br />&nbsp;&nbsp;&nbsp;Permissionable: #{self.colorify(val.permissionable)}
                    <br />&nbsp;&nbsp;&nbsp;Picklist Values: " + pvals + "
                    <br />&nbsp;&nbsp;&nbsp;Preceision: #{self.colorify2(val.precision)}
                    <br />&nbsp;&nbsp;&nbsp;Query by Distance: #{self.colorify(val.queryByDistance)}
                    <br />&nbsp;&nbsp;&nbsp;Reference to: #{self.colorify2(val.referenceTo)}
                    <br />&nbsp;&nbsp;&nbsp;Relationship Name: #{self.colorify2(val.relationshipName)}
                    <br />&nbsp;&nbsp;&nbsp;Relationship Order: #{self.colorify2(val.relationshipOrder)}
                    <br />&nbsp;&nbsp;&nbsp;Restricted Delete: #{self.colorify(val.restrictedDelete)}
                    <br />&nbsp;&nbsp;&nbsp;Restricted Picklist: #{self.colorify(val.restrictedPicklist)}
                    <br />&nbsp;&nbsp;&nbsp;Scale: #{self.colorify2(val.scale)}
                    <br />&nbsp;&nbsp;&nbsp;Soap Type: #{self.colorify2(val.soapType)}
                    <br />&nbsp;&nbsp;&nbsp;Sortable: #{self.colorify(val.sortable)}
                    <br />&nbsp;&nbsp;&nbsp;Type: #{self.colorify2(val.type)}
                    <br />&nbsp;&nbsp;&nbsp;unique: #{self.colorify(val.unique)}
                    <br />&nbsp;&nbsp;&nbsp;Updateable: #{self.colorify(val.updateable)}
                    <br />&nbsp;&nbsp;&nbsp;Write Requires Master Record: #{self.colorify(val.writeRequiresMasterRead)}", false
                  return
              )

            if foundDescribe
              self.sfdcUtilsProgressBarView.setStatus 'Finished'
            else
              self.sfdcUtilsProgressBarView.setStatus "Couldn't find #{self.selection.getText().trim()}", true
          )

        self.clearStatusBar()
        return

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
          printHeaders = true;
          table = ''
          headers = ''
          row = ''
          result.records.forEach((val, idx) ->
              if printHeaders
                printHeaders = false
                Object.keys(val).forEach((key) ->
                    if key isnt 'attributes'
                      headers += "<td>&nbsp;<strong>#{key}<strong>&nbsp;</td>"
                  )
                table += "<tr>#{headers}</tr>"

              row = ''
              Object.keys(val).forEach((key) ->
                  if key isnt 'attributes'
                    row += "<td>&nbsp;#{self.colorify2(val[key])}&nbsp;</td>"
                )
              table += "<tr>#{row}</tr>"
            )
          self.sfdcUtilsLogView.print "<table>#{table}</table>", false
          self.sfdcUtilsProgressBarView.setStatus 'Finished'
          self.clearStatusBar()
          return
        )

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
