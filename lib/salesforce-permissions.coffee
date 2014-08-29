Salesforce = require './salesforce'
_ = require 'underscore'

module.exports =
class SalesforcePermissions extends Salesforce
  constructor: (@logView, @statusBar) ->
    super(@logView, @statusBar)

  getSobjectPermissions: (sobject) ->
    un = @config.username
    pw = @config.password + @config.securityToken
    conn = new jsforce.Connection()
    self = @

    conn.login un, pw, (err, res) ->
      return console.error err if err

      self.statusBar.setStatus 'Retrieving...'
      query = "SELECT Id,
                      SobjectType,
                      PermissionsCreate,
                      PermissionsDelete,
                      PermissionsEdit,
                      PermissionsModifyAllRecords,
                      PermissionsRead,
                      PermissionsViewAllRecords,
                      Parent.ProfileId,
                      Parent.Profile.Name
                FROM
                      ObjectPermissions
                WHERE
                      SobjectType = '#{sobject}'
                ORDER BY
                      Parent.Profile.Name"

      conn.query query, (err, res) ->
        self.logView.show()
        self.logView.clear()
        self.logView.removeLastEmptyLogLine()

        if err
          self.logView.print err.toString(), true
          self.statusBar.setStatus 'Failed'
          setTimeout (=>
            self.statusBar.clear()
          ), 5000
          return

        s = '&nbsp;'
        _.each(res.records, (val, key) ->
          msg = "#{val.Parent.Profile.Name} (#{val.SobjectType}#{s}
            permissions)<br />&nbsp;&nbsp;&nbsp;&nbsp;
            create: #{self.utils.colorify(val.PermissionsCreate)}#{s}
            read: #{self.utils.colorify(val.PermissionsRead)}#{s}
            edit: #{self.utils.colorify(val.PermissionsEdit)}#{s}
            delete: #{self.utils.colorify(val.PermissionsDelete)}#{s}
            view all: #{self.utils.colorify(val.PermissionsViewAllRecords)}#{s}
            modify all: #{self.utils.colorify(val.PermissionsModifyAllRecords)}"
          self.logView.print msg, false
        )

        self.statusBar.setStatus 'Finished'
        setTimeout (=>
          self.statusBar.clear()
        ), 5000
        return

      return

  getFieldPermissions: (sobject, field) ->
    un = @config.username
    pw = @config.password + @config.securityToken
    conn = new jsforce.Connection()
    self = @

    conn.login un, pw, (err, res) ->
      return console.error err if err

      self.statusBar.setStatus 'Retrieving...'
      query = "SELECT Id,
                      Field,
                      PermissionsEdit,
                      PermissionsRead,
                      Parent.Profile.Name
                FROM
                      FieldPermissions
                WHERE
                      SobjectType = '#{sobject}'
                      AND
                      Field = '#{sobject}.#{field}'
                ORDER BY
                      Parent.Profile.Name"

      conn.query query, (err, res) ->
        self.logView.show()
        self.logView.clear()
        self.logView.removeLastEmptyLogLine()

        if err
          self.logView.print err.toString(), true
          self.statusBar.setStatus 'Failed'
          setTimeout (=>
            self.statusBar.clear()
          ), 5000
          return

        _.each(res.records, (val, key) ->
          msg = "#{val.Parent.Profile.Name} (#{val.Field}&nbsp;
            permissions)<br />&nbsp;&nbsp;&nbsp;&nbsp;
            read: #{self.utils.colorify(val.PermissionsRead)}
            edit: #{self.utils.colorify(val.PermissionsEdit)}"
          self.logView.print msg, false
        )

        self.statusBar.setStatus 'Finished'
        setTimeout (=>
          self.statusBar.clear()
        ), 5000
        return

      return
