'use babel';

import pathFn from 'path';
import fs from 'fs';

function findHexoPkg(path) {
  let pkgPath = pathFn.join(path, 'package.json');

  return new Promise((resolve, reject) => {
    fs.exists(pkgPath, (exist) => {
      if (!exist) {
        return reject();
      }

      fs.readFile(pkgPath, (err, content) => {
        if (err) {
          return reject();
        }

        let json = JSON.parse(content);
        if (typeof json.hexo === 'object') {
          resolve(path);
        } else {
          reject();
        }
      });
    });
  });
}

export default findHexoPkg;
