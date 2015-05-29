'use babel';

import pathFn from 'path';
import { Emitter, BufferedNodeProcess } from 'atom';
import untildify from 'untildify';
import findHexoPkg from './find-hexo-pkg';
import LayoutSelectView from './layout-select-view';
import NewPostView from './new-post-view';
import DraftsView from './drafts-view';

const commandScript = pathFn.join(__dirname, '/cli-adapter.js');

class Commander extends Emitter {
  constructor() {
    super();

    this.commands = {
      'atom-hexo:new': () => this.newPost(),
      'atom-hexo:generate': () => this.generate(),
      'atom-hexo:deploy': () => this.deploy(),
      'atom-hexo:publish': () => this.publish(),
      'atom-hexo:clean': () => this.clean()
    };

    this.commandQueue = [];
  }

  reset() {
    this._hasHexo = undefined;
    this.hexoPath = undefined;
    this.detachViews();
  }

  newPost() {
    this.checkHexoFolder().then(hasHexo => {
      if (!hasHexo) { return; }

      if (this.newPostView) {
        this.newPostView.detach();
      }

      this.layoutSelectView = new LayoutSelectView({
        hexoPath: this.hexoPath,
        title: 'Choose a layout to create a new post'
      });
      atom.workspace.addModalPanel({ item: this.layoutSelectView });

      this.layoutSelectView.onDidConfirmLayout((layout) => {
        this.newPostView = new NewPostView(layout);
        atom.workspace.addBottomPanel({ item: this.newPostView });

        this.newPostView.onDidConfirmPost(({layout, title}={}) => {
          this.commandQueue.push({
            name: 'new',
            args: [layout, title]
          });

          this.emit('change:status', `Creating ${layout}...`);
          this.runCommand();
        });
      });
    });
  }

  generate() {
    this.checkHexoFolder().then(hasHexo => {
      if (!hasHexo) { return; }

      this.commandQueue.push({
        name: 'generate'
      });

      this.emit('change:status', 'Generating...');
      this.runCommand();
    });
  }

  deploy() {
    this.checkHexoFolder().then(hasHexo => {
      if (!hasHexo) { return; }

      this.commandQueue.push({
        name: 'deploy',
        args: ['--generate']
      });

      this.emit('change:status', 'Deploying...');
      this.runCommand();
    });
  }

  clean() {
    this.checkHexoFolder().then(hasHexo => {
      if (!hasHexo) { return; }

      this.commandQueue.push({
        name: 'clean'
      });

      this.emit('change:status', 'Cleaning...');
      this.runCommand();
    });
  }

  publish() {
    this.checkHexoFolder().then(hasHexo => {
      if (!hasHexo) { return; }

      this.draftsView = new DraftsView(this.hexoPath);
      atom.workspace.addModalPanel({ item: this.draftsView });

      this.draftsView.onDidConfirmDraft((draftFile) => {
        this.layoutSelectView = new LayoutSelectView({
          hexoPath: this.hexoPath,
          title: 'Choose a layout to publish the post'
        });
        atom.workspace.addModalPanel({ item: this.layoutSelectView });

        this.layoutSelectView.onDidConfirmLayout((layout) => {
          let filename = pathFn.basename(draftFile, pathFn.extname(draftFile));

          this.commandQueue.push({
            name: 'publish',
            args: [layout, filename]
          });

          this.emit('change:status', 'Publishing...');
          this.runCommand();
        });
      });
    });
  }

  detachViews() {
    if (this.newPostView) {
      this.newPostView.detach();
      this.newPostView = null;
    }

    if (this.layoutSelectView) {
      this.layoutSelectView.detach();
      this.layoutSelectView = null;
    }
  }

  runCommand() {
    if (this.commandRunning || this.commandQueue.length === 0) { return; }

    this.commandRunning = true;
    let command = this.commandQueue.shift();

    if (!command.args) {
      command.args = [];
    }
    command.args.unshift(command.name);
    command.args.push.apply(command.args, ['--hexoPath', this.hexoPath]);

    return new BufferedNodeProcess({
      command: commandScript,
      args: command.args,
      stdout: (stdout) => {
        let result = {};
        try {
          result = JSON.parse(stdout);
        } catch (err) {
          console.error(err);
        }

        switch (result.event) {
        case 'new':
          this.handleNewAfter(result.message);
          break;
        case 'publishAfter':
        case 'generateAfter':
        case 'deployAfter':
        case 'cleanAfter':
          this.handleCommandSuccess(command.name);
          break;
        }
      },
      stderr: (err) => {
        atom.notifications.addError('Atom-Hexo Error', {
          detail: `Execute the '${command.name}' command fails!\n${err}`
        });
      },
      exit: (status) => {
        this.emit('clear:status');
        this.commandRunning = false;
        this.runCommand();
      }
    });
  }

  handleNewAfter(postPath) {
    atom.workspace.open(postPath);
  }

  handleCommandSuccess(command) {
    this.emit('clear:status');
    atom.notifications.addSuccess('Atom-Hexo', {
      detail: `Execute the ${command} command successfully!`
    });
  }

  checkHexoFolder() {
    this.emit('change:status', 'Loading hexo...');

    return Promise.resolve().then(() => {
      if (this._hasHexo !== undefined) {
        return this._hasHexo;
      }

      let cwdConf = untildify(atom.config.get('atom-hexo.currentWorkingDirectory'));
      if (cwdConf) {
        return findHexoPkg(cwdConf).then((path) => {
          this.hexoPath = path;
          return true;
        }).catch(() => {
          atom.notifications.addError('Atom-Hexo Error', {
            detail: `Local hexo folder is not found in the ${cwdConf}!`
          });
          return false;
        });
      }

      let directories = atom.project.getDirectories();
      let findPkgs = directories.map((directory) => {
        return findHexoPkg(directory.getPath()).then((path) => {
          this.hexoPath = path;
        });
      });

      return Promise.all(findPkgs).then(() => {
        if (!this.hexoPath) {
          atom.notifications.addError('Atom-Hexo Error', {
            detail: 'Local hexo folder is not found in the projects!'
          });
          return false;
        }

        return true;
      });
    }).then((hasHexo) => {
      this.emit('clear:status');
      this._hasHexo = hasHexo;
      return hasHexo;
    });
  }
}

export default Commander;
