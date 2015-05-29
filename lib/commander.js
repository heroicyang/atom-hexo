'use babel';

import pathFn from 'path';
import { Emitter, BufferedNodeProcess } from 'atom';
import untildify from 'untildify';
import findHexoPkg from './find-hexo-pkg';
import NewPostView from './new-post-view';
import DraftsView from './drafts-view';

const commandScript = pathFn.join(__dirname, '/cli-adapter.js');
const draftsPath = '/source/_drafts';

class Commander extends Emitter {
  constructor() {
    super();

    this.commands = {
      'atom-hexo:new-post': () => this.newPost(),
      'atom-hexo:new-page': () => this.newPost('page'),
      'atom-hexo:new-draft': () => this.newPost('draft'),
      'atom-hexo:generate': () => this.generate(),
      'atom-hexo:deploy': () => this.deploy(),
      'atom-hexo:publish': () => this.publish(),
      'atom-hexo:clean': () => this.clean(),
      'atom-hexo:list-drafts': () => this.listDrafts()
    };

    this.commandQueue = [];
  }

  reset() {
    this._hasHexo = undefined;
    this.hexoPath = undefined;
    this.detachViews();
  }

  newPost(layout='post') {
    this.checkHexoFolder().then(hasHexo => {
      if (!hasHexo) { return; }

      if (this.newPostView) {
        this.newPostView.detach();
      }

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

  publish() {
    this.checkHexoFolder().then(hasHexo => {
      if (!hasHexo) { return; }

      let draftFile = atom.workspace.getActiveTextEditor().getPath();
      if (draftFile) {
        let filename = pathFn.basename(draftFile, pathFn.extname(draftFile));

        if (draftFile.indexOf(draftsPath) === -1) {
          return atom.notifications.addWarning('Atom-Hexo Warning', {
            detail: `Draft "${filename}" does not exist!`
          });
        }

        this.commandQueue.push({
          name: 'publish',
          args: [filename]
        });

        this.emit('change:status', 'Publishing...');
        this.runCommand();
      }
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

  listDrafts() {
    this.checkHexoFolder().then(hasHexo => {
      if (!hasHexo) { return; }

      if (!this.draftsView) {
        this.draftsView = new DraftsView(this.cwd);
        atom.workspace.addModalPanel({ item: this.draftsView });

        this.draftsView.onDidConfirmDraftItem((draftFile) => {
          atom.workspace.open(pathFn.join(this.cwd, draftFile));
        });
      }

      this.draftsView.toggle();
    });
  }

  detachViews() {
    if (this.newPostView) {
      this.newPostView.detach();
      this.newPostView = null;
    }

    if (this.draftsView) {
      this.draftsView.detach();
      this.draftsView = null;
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
        try {
          let result = JSON.parse(stdout);
          switch (result.event) {
          case 'new':
            this.handleNewAfter(result.message);
            break;
          case 'generateAfter':
          case 'deployAfter':
          case 'publishAfter':
          case 'cleanAfter':
            this.handleCommandSuccess(command.name);
            break;
          }
        } catch (err) {
          console.error(err);
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
