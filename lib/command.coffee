{BufferedProcess} = require 'atom'

module.exports =
class Command
  @bufferedProcess: null
  @argsHash:
    'new': ['new']
    generate: ['generate']
    deploy: ['generate', '--deploy']
    clean: ['clean']
    publish: ['publish']

  exec: (cmd, args = []) ->
    return unless cmd and not @processing()

    atom.workspaceView.trigger 'hexo:before-command', cmd

    command = 'hexo'
    args = @constructor.argsHash[cmd].concat args
    options =
      cwd: atom.project.getPath()
      env: process.env

    stdout = (stdout) ->
      atom.workspaceView.trigger 'hexo:command-stdout', stdout
    stderr = (stderr) ->
      atom.workspaceView.trigger 'hexo:command-stderr', stderr
    exit = (exitCode) =>
      atom.workspaceView.trigger 'hexo:command-exit', {cmd, exitCode}
      @terminate()

    @constructor.bufferedProcess = new BufferedProcess({command, args, options, stdout, stderr, exit})

  processing: ->
    @constructor.bufferedProcess? and @constructor.bufferedProcess.process?

  terminate: ->
    if @constructor.bufferedProcess? and @constructor.bufferedProcess.process?
      @constructor.bufferedProcess.kill()