{$, BufferedProcess} = require 'atom'
PostCreateView = require './post-create-view'
ResultsView = require './results-view'

module.exports =
  activate: ({@postCreateViewState, @resultsViewState} = {}) ->
    @postCreateView = new PostCreateView(@postCreateViewState)
    @resultsView = new ResultsView(@resultsViewState)

    atom.workspaceView.on 'atom-hexo:generate', =>
      @generate()

    atom.workspaceView.on 'atom-hexo:deploy', =>
      @deploy()

    atom.workspaceView.on 'hexo:show-results', (event, data) =>
      @display data.css, data.line

    atom.workspaceView.on 'core:cancel core:close', =>
      @postCreateView?.detach()
      @resultsView?.detach()

  generate: ->
    return if @processing()

    command = 'hexo'
    args = ['generate']
    options =
      cwd: atom.project.getPath()
      env: process.env

    stdout = (output) =>
      @display 'stdout', output

    stderr = (stderr) =>
      @display 'stderr', stderr
    
    exit = (code) =>
      @stop()
      console.log "Exited with #{code}"

    @bufferedProcess = new BufferedProcess({command, args, options, stdout, stderr, exit})

  deploy: ->
    return if @processing()

    command = 'hexo'
    args = ['generate', '--deploy']
    options =
      cwd: atom.project.getPath()
      env: process.env

    stdout = (output) =>
      @display 'stdout', output

    stderr = (stderr) =>
      @display 'stderr', stderr
    
    exit = (code) =>
      @stop()
      console.log "Exited with #{code}"

    @bufferedProcess = new BufferedProcess({command, args, options, stdout, stderr, exit})

  processing: ->
    @bufferedProcess? and @bufferedProcess.process?

  stop: ->
    if @bufferedProcess? and @bufferedProcess.process?
      @bufferedProcess.kill()

  display: (css, line) ->
    @resultsView?.attach()
    @resultsView?.display css, line

  deactivate: ->
    @postCreateView?.detach()
    @resultsView?.detach()

  serialize: ->
    postCreateViewState: @postCreateView?.serialize() ? @postCreateViewState
    resultsViewState: @resultsView?.serialize() ? @resultsViewState