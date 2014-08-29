# TODO
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
