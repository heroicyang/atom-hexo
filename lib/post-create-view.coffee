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

  initialize: ({serializeState, @layout}={}) ->
    @handleEvents()

  showPostCreateEditor: ->
    atom.workspaceView.prependToBottom(this) if not @hasParent()

    @setEditorLabel()
    @postCreateEditor.focus()
    @postCreateEditor.getEditor().selectAll()

  handleEvents: ->
    @postCreateEditor.on 'core:confirm', =>
      @createPost @postCreateEditor.getText()

  setPostLayout: (layout) ->
    @layout = layout

  setEditorLabel: ->
    editorLabel = "#{(@layout.substr 0, 1).toUpperCase()}#{@layout.substr(1)} Title: "
    @editorLabel.text(editorLabel)

  createPost: (title) ->
    process.chdir atom.project.getPath()

    command = 'hexo'
    args = ['new', @layout, title]
    options =
      cwd: atom.project.getPath()
      env: process.env
    stdout = (output) =>
      postFile = output.substr output.indexOf(atom.project.getPath())
      postFile = postFile.replace '\n', ''

      atom.workspaceView.open(postFile).done () =>
        @detach()
    stderr = (stderr) ->
      console.log(stderr)

    @bufferedProcess = new BufferedProcess({command, args, options, stdout, stderr})