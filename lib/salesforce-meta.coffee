Salesforce = require './salesforce'
path = require 'path'
fs = require 'fs'
sax = require 'sax'
strict = true
parser = sax.parser(strict)

# [SalesforceMeta]
# Handles API calls that crud sobjects
# and fields
module.exports =
class SalesforceMeta extends Salesforce
  _filePath = null
  _metaFilePath = null
  _metaComponent = null
  _extensions = {
    ".cls": "ApexClass"
    ".page": "ApexPage"
    ".trigger": "ApexTrigger"
    ".component": "ApexComponent"
    ".object": "CustomObject"
    ".cls-meta.xml": "ApexClass"
    ".page-meta.xml": "ApexPage"
    ".trigger-meta.xml": "ApexTrigger"
    ".component-meta.xml": "ApexComponent" }

  constructor: (filePath, @logView, @statusBar) ->
    super(@logView, @statusBar)

    @_filePath = filePath
    fileExt = @_getFileExt()

    @_metaComponent = _extensions[fileExt]
    if !_extensions[fileExt]
      @_filePath = null
      @_metaComponent = null
      return

    if fileExt.indexOf('-meta.xml') != -1
      @_metaFilePath = @_filePath
      @_filePath = @_filePath.replace('-meta.xml', '')
    else
      @_metaFilePath = "#{@_filePath}-meta.xml"

  save: ->
    metadata = @_createMetadata()
    self = @

    @statusBar.setStatus 'Saving...'
    @login (err, res) ->
      return console.error err if err

      self.conn.metadata.upsertAsync self._metaComponent,
        metadata, (err, res) ->
        return console.error err if err

        if res.success
          self.statusBar.setStatus "#{res.fullName} saved to Salesforce"
        else
          self.logView.show()
          self.logView.clear()
          self.statusBar.setStatus "Error saving to Salesforce"
          self.logView.print err, true if err
          self.logView.print "Error<br />
              #{JSON.stringify(res.errors, null, 2).replace(/\\/g, '')}" , true

        # fade out the current status bar value
        setTimeout (=>
          self.statusBar.clear()
        ), 5000
        return

  _createMetadata: ->
    @statusBar.setStatus 'Packaging metadata...'
    metadata = [{ content: @_getFileContents(@_filePath, 'base64') }]
    tag = null
    self = @

    parser.onerror = (e) ->
      return console.error e if e

    parser.ontext = (t) ->
      if t and t.trim().length > 0 and tag and tag.length > 0
        metadata[0]["#{tag}"] = t
        tag = null

    parser.onopentag = (node) ->
      tag = node.name

    parser.onend = ->
      if !metadata[0].fullName
        name = path.basename(self._filePath).split('.')
        metadata[0].fullName = name[0]

    xml = @_getFileContents(@_metaFilePath)
    parser.write(xml).close()

    return metadata

  _getFileContents: (filePath, encoding = null) ->
    return Buffer(fs.readFileSync(filePath)).toString(encoding)

  _removeXmlNamespace: (xml) ->
    return xml.replace(' xmlns="http://soap.sforce.com/2006/04/metadata"', '')

  _getFileExt: ->
    fileName = path.basename(@_filePath)
    parts = fileName.split('.')

    if parts.length > 2
      return ".#{parts[parts.length - 2]}.#{parts[parts.length - 1]}"
    else
      return ".#{parts[parts.length - 1]}"
