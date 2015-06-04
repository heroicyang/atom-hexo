'use babel';

import { CompositeDisposable } from 'atom';
import Commander from './commander';
import StatusBarView from './status-bar-view';

export default {
  config: {
    currentWorkingDirectory: {
      'type': 'string',
      'default': ''
    }
  },

  activate() {
    this.commander = new Commander();
    this.subscriptions = new CompositeDisposable();

    Object.keys(this.commander.commands).forEach((key) => {
      this.subscriptions.add(
        atom.commands.add('atom-workspace', key, this.commander.commands[key])
      );
    });

    this.subscriptions.add(
      atom.commands.add('atom-workspace', {
        'core:close': () => this.commander.detachViews(),
        'core:cancel': () => this.commander.detachViews()
      })
    );

    this.subscriptions.add(
      this.commander.on('change:status', this.updateStatusBar.bind(this))
    );
    this.subscriptions.add(
      this.commander.on('clear:status', this.hideStatusBar.bind(this))
    );
  },

  deactivate() {
    this.commander.dispose();
    this.subscriptions.dispose();
    this.commander = null;
    this.subscriptions = null;
  },

  consumeStatusBar(statusBar) {
    this.statusBarView = new StatusBarView();
    statusBar.addLeftTile({ item: this.statusBarView });
  },

  updateStatusBar(msg) {
    if (this.statusBarView) {
      this.statusBarView.update(msg);
      this.statusBarView.show();
    }
  },

  hideStatusBar() {
    if (this.statusBarView) {
      this.statusBarView.hide();
    }
  }
};
