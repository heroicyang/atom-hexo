'use babel';

import pathFn from 'path';
import fs from 'fs-plus';
import { Emitter } from 'atom';
import { $$, SelectListView, View } from 'atom-space-pen-views';

const draftsPath = '/source/_drafts';
const fileExts = ['.markdown', '.md', '.mdown', '.mkd', '.mkdown', '.ron'];

class DraftsView extends SelectListView {
  constructor(cwd) {
    super();

    this.emitter = new Emitter();
    this.cwd = cwd;

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

    this.emitter.emit('confirm', pathFn.join(draftsPath, name));
    this.hide();
  }

  detached() {
    this.emitter.dispose();
  }

  onDidConfirmDraftItem(callback) {
    return this.emitter.on('confirm', callback);
  }

  toggle() {
    if (this.panel && this.panel.isVisible()) {
      this.hide();
    } else {
      this.show();
    }
  }

  show() {
    this.panel = atom.workspace.panelForItem(this);
    this.panel.show();

    this.storeFocusedElement();
    this.setLoading('Loading drafts...');

    fs.list(pathFn.join(this.cwd, draftsPath), fileExts, (err, files) => {
      if (err) {
        return this.setError(err.message || 'Load the drafts fails!');
      }

      if (files && files.length > 0) {
        this.setItems(files);
      } else {
        this.setError('There\'s no draft!');
      }

      this.setLoading('');
    });

    this.focusFilterEditor();
  }

  hide() {
    if (this.panel) {
      this.panel.hide();
    }
  }
}

export default DraftsView;
