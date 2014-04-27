{View, EditorView} = require 'atom'

module.exports =
class PostCreateView extends View
  @content: ({layout}) ->
    labelText = "#{layout[0...1].toUpperCase()}#{layout[1..]} Title: "

    @div tabIndex: -1, class: 'atom-hexo tool-panel panel-bottom', =>
      @div class: 'post-create-form padded block', =>
        @span outlet: 'editorLabel', class: 'editor-label', labelText
        @div class: 'editor-container', =>
          @subview 'postTitleEditor', new EditorView(mini: true, placeholderText: 'Type your title here...')

  initialize: ({@layout} = {layout: 'post'}) ->
    atom.workspaceView.prependToBottom(this) unless @hasParent()
    @postTitleEditor.focus()
    @postTitleEditor.getEditor().selectAll()

    @postTitleEditor.on 'core:confirm', =>
      postTitle = @postTitleEditor.getText()
      return unless postTitle

      atom.workspaceView.trigger 'hexo:exec-command', cmd: 'new', args: [@layout, postTitle]
      @detach()