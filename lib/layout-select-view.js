'use babel';

import pathFn from 'path';
import fs from 'fs';
import { Emitter } from 'atom';
import { $$, SelectListView, View } from 'atom-space-pen-views';

const scaffoldDir = '/scaffolds';

class LayoutSelectListView extends SelectListView {
  constructor() {
    super();

    this.emitter = new Emitter();
  }

  viewForItem(item) {
    return $$(() => View.li(item));
  }

  cancelled() {
    this.emitter.emit('cancel');
  }

  confirmed(name) {
    if (!name) { return; }

    this.emitter.emit('confirm', name);
  }

  attached() {
    this.storeFocusedElement();
    this.setLoading('Loading layout...');
  }

  detached() {
    this.emitter.dispose();
  }

  onDidConfirmLayout(callback) {
    return this.emitter.on('confirm', callback);
  }

  onDidCancel(callback) {
    return this.emitter.on('cancel', callback);
  }
}

class LayoutSelectView extends View {
  static content() {
    LayoutSelectView.div({
      'class': 'atom-hexo-layout-select'
    }, () => {
      LayoutSelectView.div({
        'class': 'title',
        outlet: 'titleLabel'
      });

      LayoutSelectView.subview('selectListView', new LayoutSelectListView());
    });
  }

  constructor({hexoPath, title}={}) {
    super();

    this.emitter = new Emitter();
    this.hexoPath = hexoPath;
    this.title = title;

    this.selectListView.onDidConfirmLayout((layout) => {
      this.emitter.emit('confirm', layout);
      this.hide();
    });

    this.selectListView.onDidCancel(() => this.detach());
  }

  attached() {
    this.titleLabel.text(this.title);

    this.panel = atom.workspace.panelForItem(this);
    this.panel.show();

    fs.readdir(pathFn.join(this.hexoPath, scaffoldDir), (err, files) => {
      if (err) {
        return this.selectListView.setError(err.message || 'Load the layout fails!');
      }

      if (files && files.length > 0) {
        let items = files.map((item) => {
          return item.substring(0, item.length - pathFn.extname(item).length);
        });
        this.selectListView.setItems(items);
      } else {
        this.selectListView.setItems(['default']);
      }

      this.selectListView.setLoading('');
      this.selectListView.focusFilterEditor();
    });
  }

  detached() {
    this.hide();
    this.emitter.dispose();
  }

  hide() {
    if (this.panel) {
      this.panel.hide();
    }
  }

  onDidConfirmLayout(callback) {
    return this.emitter.on('confirm', callback);
  }
}

export default LayoutSelectView;
