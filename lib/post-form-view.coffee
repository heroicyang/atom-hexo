path = require 'path'
{View, EditorView, BufferedProcess} = require 'atom'

module.exports = 
class PostFormView extends View
  @bufferedProcess: null

  @content: ->
    @div tabIndex: -1, class: 'atom-hexo tool-panel panel-bottom', =>
      @div class: 'post-form-view padded block', =>
        @span 'Post Titile', outlet: 'editorLabel', class: 'editor-label'
        @div class: 'editor-container', =>
          @subview 'postTitleEditor', new EditorView(mini: true, placeholderText: 'Type your title here...')

  initialize: (serializeState) ->
    @handleEvents()

    atom.workspaceView.command 'atom-hexo:new-post', =>
      @showPostTitleEditor()

    atom.workspaceView.command 'atom-hexo:new-page', =>
      @showPostTitleEditor 'page'

    atom.workspaceView.command 'atom-hexo:new-draft', =>
      @showPostTitleEditor 'draft'

  serialize: ->

  attach: ->
    atom.workspaceView.prependToBottom(this) unless @hasParent()
    atom.workspaceView.trigger 'hexo:hide-results'

  detach: () ->
    return unless @hasParent()
    super()

  handleEvents: ->
    @postTitleEditor.on 'core:confirm', =>
      @createPost @postTitleEditor.getText()

  showPostTitleEditor: (@layout = 'post') ->
    @attach()
    @setEditorLabel()
    @postTitleEditor.focus()
    @postTitleEditor.getEditor().selectAll()

  setEditorLabel: ->
    editorLabel = "#{@layout[0...1].toUpperCase()}#{@layout[1..]} Title: "
    @editorLabel.text(editorLabel)

  createPost: (title) ->
    return unless title

    hexoPath = atom.project.getPath()
    projectPathError = 
      message: 'Warning: Please open your Hexo folder as the root project.'
      className: 'warning'

    if not hexoPath
      return @displayError projectPathError

    command = 'hexo'
    args = ['new', @layout, title]
    options =
      cwd: hexoPath
      env: process.env

    stdout = (output) =>
      if -1 != output.indexOf 'Usage'
        @displayError projectPathError
      else
        postFile = output[output.indexOf(atom.project.getPath())..]
        postFile = postFile.replace '\n', ''

        atom.workspaceView.open(postFile).done () =>
          @detach()

    stderr = (stderr) =>
      @displayError message: stderr, className: 'stderr'

    PostFormView.bufferedProcess = new BufferedProcess({command, args, options, stdout, stderr})

  displayError: (result) ->
    @detach()
    atom.workspaceView.trigger 'hexo:show-results', result