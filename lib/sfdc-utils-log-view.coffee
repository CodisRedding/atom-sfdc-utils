{View} = require 'atom'
$ = require('atom').$

module.exports =
class SfdcUtilsLogView extends View
  lastHeader = null
  textBuffer = null
  lastMessageType = null

  @content: ->
      @div tabIndex: -1, class: 'sfdc-utils-log-view tool-panel bottom-bottom', =>
        @ul outlet: 'canvas', class: 'list-tree'

  initialize: (serializeState) ->
    @textBuffer = $("<pre class=\"stderr\">")

  # Returns an object that can be retrieved when package is activated
  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @detach()

  toggle: ->
    if @hasParent()
      @detach()
    else
      atom.workspaceView.prependToBottom(this)

  show: ->
    if not @hasParent()
      atom.workspaceView.prependToBottom(this)

  removeTerminalColors: (text) ->
    text.replace(/\[[0-9]+m/g, '')

  removeLastEmptyLogLine: ->
    lastPre = @canvas.find('li.list-item:last-child pre.output:last-child')
    if lastPre.text() == ''
      lastPre.remove()

  print: (line, stderr = false, append = false) ->
    # console.log 'print: %s', line
    # If we are scrolled all the way down we follow the output
    panel = @canvas.parent()
    at_bottom = (panel.scrollTop() + panel.innerHeight() + 10 > panel[0].scrollHeight)

    # Header
    line = @removeTerminalColors line

    # Remove last newline from previous <pre>
    @removeLastEmptyLogLine()

    icon = 'file-code'
    errClass = 'text-error' if stderr

    lastHeader = icon
    @canvas.append $("<li class=\"list-item\">
                        <div class=\"list-item\">
                          <pre class=\"icon icon-#{icon} #{errClass}\">#{line}</pre>
                        </div>
                      </li")

    if at_bottom
      panel.scrollTop(panel[0].scrollHeight)

  clear: ->
    @canvas.empty()
