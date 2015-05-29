'use babel';

import pathFn from 'path';
import fs from 'fs';
import { Emitter } from 'atom';
import { $$, SelectListView, View } from 'atom-space-pen-views';

const draftsDir = '/source/_drafts';

class DraftsView extends SelectListView {
  constructor(hexoPath) {
    super();

    this.emitter = new Emitter();
    this.hexoPath = hexoPath;

    this.addClass('atom-hexo-drafts');
    this.setMaxItems(10);
  }

  viewForItem(item) {
    return $$(() => {
      View.li(() => {
        View.div({
          'class': 'icon icon-file-text'
        }, item);
      });
    });
  }

  setItems(items) {
    super.setItems(items.map((item) => {
      return pathFn.basename(item);
    }));
  }

  cancelled() {
    this.hide();
  }

  confirmed(name) {
    if (!name) { return; }

    this.emitter.emit('confirm', pathFn.join(draftsDir, name));
    this.hide();
  }

  attached() {
    this.panel = atom.workspace.panelForItem(this);
    this.panel.show();

    this.storeFocusedElement();
    this.setLoading('Loading drafts...');

    fs.readdir(pathFn.join(this.hexoPath, draftsDir), (err, files) => {
      if (err) {
        return this.setError(err.message || 'Load the drafts fails!');
      }

      if (files && files.length > 0) {
        this.setItems(files);
      } else {
        this.setError('There\'s no draft!');
      }

      this.setLoading('');
      this.focusFilterEditor();
    });
  }

  detached() {
    this.emitter.dispose();
  }

  hide() {
    if (this.panel) {
      this.panel.hide();
    }
  }

  onDidConfirmDraft(callback) {
    return this.emitter.on('confirm', callback);
  }
}

export default DraftsView;
