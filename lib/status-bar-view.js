'use babel';

import { View } from 'atom-space-pen-views';

class StatusBarView extends View {
  static content() {
    StatusBarView.div({
      'class': 'atom-hexo-status inline-block',
      tabIndex: -1
    }, () => {
      StatusBarView.span({
        'class': 'status-loader'
      }, 'H');

      StatusBarView.span({
        'class': 'status-message',
        outlet: 'statusMessage'
      });
    });
  }

  update(msg) {
    this.statusMessage.text(msg);
  }
}

export default StatusBarView;
