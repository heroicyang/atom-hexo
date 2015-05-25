'use babel';

import { Emitter } from 'atom';
import { View, TextEditorView } from 'atom-space-pen-views';

class NewPostView extends View {
  static content() {
    NewPostView.div({
      tabIndex: -1,
      'class': 'atom-hexo tool-panel panel-bottom'
    }, () => {
      NewPostView.div({
        'class': 'new-post-form padded block'
      }, () => {
        NewPostView.span({
          outlet: 'editorLabel',
          'class': 'editor-label'
        });

        NewPostView.div({
          'class': 'editor-container'
        }, () => {
          NewPostView.subview('editor', new TextEditorView({
            mini: true,
            placeholderText: 'Type your title here...'
          }));
        });
      });
    });
  }

  constructor(layout='post') {
    super();

    this.emitter = new Emitter();
    this.layout = layout;

    this.subscription = atom.commands.add(this.editor.element, 'core:confirm', () => {
      let title = this.editor.getText();
      if (!title) { return; }

      this.emitter.emit('confirm', { layout: this.layout, title });
      this.detach();
    });
  }

  onDidConfirmPost(callback) {
    return this.emitter.on('confirm', callback);
  }

  attached() {
    let label = this.layout.substr(0, 1).toUpperCase() + this.layout.substr(1);
    this.editorLabel.text(`${label} Title: `);

    this.editor.focus();
  }

  detached() {
    this.emitter.dispose();
    this.subscription.dispose();
  }
}

export default NewPostView;
