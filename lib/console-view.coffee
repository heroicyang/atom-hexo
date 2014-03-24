{View, BufferedProcess} = require 'atom'

module.exports = 
class ConsoleView extends View
  @bufferedProcess: null

  @content: ->
    @div tabIndex: -1, class: 'atom-hexo panel tool-panel panel-bottom', =>
      @div outlet: 'consolePanel', class: 'panel-body console-panel'

  initialize: (serializeState) ->
    atom.workspaceView.prependToBottom(this) if not @hasParent()

  generate: ->
    process.chdir atom.project.getPath()

    command = 'hexo'
    args = ['generate']
    options =
      cwd: atom.project.getPath()
      env: process.env
    stdout = (output) =>
      @display 'stdout', output
    stderr = (stderr) =>
      @display 'stderr', stderr
    exit = (code) ->
      console.log "Exited with #{code}"

    @bufferedProcess = new BufferedProcess({command, args, options, stdout, stderr, exit})

  deploy: ->

  generateAndDeploy: ->

  publish: ->

  close: ->
    @stop()
    @detach() if @hasParent()

  stop: ->
    if @bufferedProcess? and @bufferedProcess.process?
      @bufferedProcess.kill()
      @display('stdout', 'Command canceled!')

  display: (css, line) ->
    @consolePanel.append "<pre class='line #{css}'>#{line}</pre>"
    @consolePanel.scrollTop @consolePanel[0].scrollHeight