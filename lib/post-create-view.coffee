path = require 'path'
{View, EditorView, BufferedProcess} = require 'atom'

module.exports = 
class PostCreateView extends View
  @bufferedProcess: null

  @content: ->
    @div tabIndex: -1, class: 'atom-hexo tool-panel panel-bottom', =>
      @div class: 'post-create-view-container block', =>
        @span outlet: 'editorLabel', class: 'editor-label pull-left', 'Post Titile'

        @subview 'postCreateEditor', new EditorView(mini: true)

  initialize: (serializeState) ->
    @handleEvents()

    atom.workspaceView.command 'atom-hexo:new-post', =>
      @showPostCreateEditor()

    atom.workspaceView.command 'atom-hexo:new-page', =>
      @showPostCreateEditor 'page'

    atom.workspaceView.command 'atom-hexo:new-draft', =>
      @showPostCreateEditor 'draft'

  serialize: ->

  attach: ->
    atom.workspaceView.prependToBottom(this) unless @hasParent()

  detach: () ->
    return unless @hasParent()
    super()

  handleEvents: ->
    @postCreateEditor.on 'core:confirm', =>
      @createPost @postCreateEditor.getText()

  showPostCreateEditor: (@layout = 'post') ->
    @attach()
    @setEditorLabel()
    @postCreateEditor.focus()
    @postCreateEditor.getEditor().selectAll()

  setEditorLabel: ->
    editorLabel = "#{@layout[0...1].toUpperCase()}#{@layout[1..]} Title: "
    @editorLabel.text(editorLabel)

  createPost: (title) ->
    hexoPath = atom.project.getPath()
    return unless title and hexoPath

    command = 'hexo'
    args = ['new', @layout, title]
    options =
      cwd: hexoPath
      env: process.env

    stdout = (output) =>
      if -1 != output.indexOf 'Usage'
        @detach()
        data = 
          css: 'warning'
          line: 'Please use the Atom to open your Hexo folder as a project!'
        atom.workspaceView.trigger 'hexo:show-results', data
      else
        postFile = output[output.indexOf(atom.project.getPath())..]
        postFile = postFile.replace '\n', ''

        atom.workspaceView.open(postFile).done () =>
          @detach()

    stderr = (stderr) =>
      @detach()
      data = 
          css: 'stderr'
          line: stderr
        atom.workspaceView.trigger 'hexo:show-results', data

    PostCreateView.bufferedProcess = new BufferedProcess({command, args, options, stdout, stderr})