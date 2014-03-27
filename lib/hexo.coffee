{BufferedProcess} = require 'atom'
PostCreateView = require './post-create-view'
ResultsView = require './results-view'

module.exports =
  activate: ({@postCreateViewState, @resultsViewState} = {}) ->
    @postCreateView = new PostCreateView(@postCreateViewState)
    @resultsView = new ResultsView(@resultsViewState)

    atom.workspaceView.on 'atom-hexo:generate', =>
      @resultsView?.clear()
      @generate() unless @processing()

    atom.workspaceView.on 'atom-hexo:deploy', =>
      @resultsView?.clear()
      @deploy() unless @processing()

    atom.workspaceView.on 'hexo:show-results', (event, data) =>
      @display data.css, data.line

    atom.workspaceView.on 'hexo:close-results', =>
      @resultsView?.clear()
      @resultsView?.detach()

    atom.workspaceView.on 'core:cancel core:close', =>
      @postCreateView?.detach()
      @resultsView?.detach()

  generate: ->
    command = 'hexo'
    args = ['generate']
    options =
      cwd: atom.project.getPath()
      env: process.env

    stdout = (output) =>
      @displayOutput(output)

    stderr = (stderr) =>
      @displayError stderr
    
    exit = (code) =>
      @processExit code, 'generate'

    @bufferedProcess = new BufferedProcess({command, args, options, stdout, stderr, exit})

  deploy: ->
    command = 'hexo'
    args = ['generate', '--deploy']
    options =
      cwd: atom.project.getPath()
      env: process.env

    stdout = (output) =>
      @displayOutput(output)

    stderr = (stderr) =>
      @displayError stderr
    
    exit = (code) =>
      @processExit code, 'deploy'

    @bufferedProcess = new BufferedProcess({command, args, options, stdout, stderr, exit})

  displayOutput: (output) ->
    if -1 != output.indexOf 'Usage'
      @hasWarning = true
      css = 'warning'
      line = 'Please open your Hexo folder as the root project!'
    else
      css = 'stdout'
      line = output

    @display css, line

  displayError: (stderr) ->
    @hasError = true
    # fix output when deploy to github
    if /(:|\/)([^\/]+)\/([^\/]+)\.git\/?/.test(stderr) or /([\d\w]+)..(\d\w+)/.test(stderr)
      @hasError = false
      @display 'stdout', stderr
    else
      @display 'stderr', stderr

  processExit: (code, cmd) ->
    if code is 0
      if @hasError
        @display 'stderr', "Error!!! For details, please see the log!"
      else if not @hasWarning
        @display 'success', "Hexo `#{cmd}` command execute successfully!"
    else
      @display 'stderr', 'Oops...Seems wrong somewhere!'

    @hasWarning = @hasError = false

    @stop()

  processing: ->
    @bufferedProcess? and @bufferedProcess.process?

  stop: ->
    if @bufferedProcess? and @bufferedProcess.process?
      @bufferedProcess.kill()

  display: (css, line) ->
    return unless line
    line = line.replace /(\[\d+m)/g, ''

    @resultsView?.attach()
    @resultsView?.display css, line

  deactivate: ->
    @postCreateView?.detach()
    @resultsView?.detach()

  serialize: ->
    postCreateViewState: @postCreateView?.serialize() ? @postCreateViewState
    resultsViewState: @resultsView?.serialize() ? @resultsViewState