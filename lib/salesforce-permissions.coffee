Salesforce = require './salesforce'

# [SalesforcePermissions]
# Displays the persmissions for a sobject
# or field for each profile
module.exports =
class SalesforcePermissions extends Salesforce
  constructor: (@logView, @statusBar) ->
    super(@logView, @statusBar)

  # [getSobjectPermissions]
  # Displays the permissions for a sobject
  # for every profile
  getSobjectPermissions: (sobject) ->
    self = @

    # Create a connection to Salesforce
    @login (err, res) ->
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
                      Parent.Profile.Name,
                      SobjectType"

      # Call Salesforce API to run a SOQL query
      self.conn.query query, (err, res) ->
        self.logView.show()
        self.logView.clear()
        self.logView.removeLastEmptyLogLine()

        if err
          self.logView.print err.toString(), true
          self.statusBar.setStatus 'Failed'
          # fade out the current status bar value
          setTimeout (=>
            self.statusBar.clear()
          ), 5000
          return

        # Format and display the permissions for each
        # sobject for each profile
        s = '&nbsp;'
        res.records.forEach (val, key) ->
          msg = "#{val.Parent.Profile.Name} (#{val.SobjectType}#{s}
            permissions)<br />&nbsp;&nbsp;&nbsp;&nbsp;
            create: #{self.utils.colorify(val.PermissionsCreate)}#{s}
            read: #{self.utils.colorify(val.PermissionsRead)}#{s}
            edit: #{self.utils.colorify(val.PermissionsEdit)}#{s}
            delete: #{self.utils.colorify(val.PermissionsDelete)}#{s}
            view all: #{self.utils.colorify(val.PermissionsViewAllRecords)}#{s}
            modify all: #{self.utils.colorify(val.PermissionsModifyAllRecords)}"
          self.logView.print msg, false

        self.statusBar.setStatus 'Finished'
        #fade out the current status bar value
        setTimeout (=>
          self.statusBar.clear()
        ), 5000
        return

      return

  # [getFieldPermissions]
  # Displays the permissions for a field
  # for every profile
  getFieldPermissions: (sobject, field) ->
    self = @

    # create a connection to Salesforce
    @login (err, res) ->
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
                      Parent.Profile.Name,
                      Field"

      # Call Salesforce API to run a SOQL query
      self.conn.query query, (err, res) ->
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

        # Format and display the permissions for each
        # field for each profile
        res.records.forEach (val, key) ->
          msg = "#{val.Parent.Profile.Name} (#{val.Field}&nbsp;
            permissions)<br />&nbsp;&nbsp;&nbsp;&nbsp;
            read: #{self.utils.colorify(val.PermissionsRead)}
            edit: #{self.utils.colorify(val.PermissionsEdit)}"
          self.logView.print msg, false

        self.statusBar.setStatus 'Finished'
        # fade out the current status bar value
        setTimeout (=>
          self.statusBar.clear()
        ), 5000
        return

      return
