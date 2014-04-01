# Atom-Hexo

> [Hexo] for the Atom Editor.

Provides [Hexo] `new`, `generate`, `deploy` commands in the Atom Editor.

![A screenshot of Atom-Hexo](http://ww2.sinaimg.cn/large/65cc6c38gw1ef0fgok3y0g20vj0km112.jpg)

## Install

```bash
apm install atom-hexo
```

You can also install `atom-hexo` by going to the `Packages` section on left hand side of the Settings view (`cmd-,`).

## Usage

Open your favorite terminal, change to the Hexo blog directory, and type `atom` to open the folder as root project. Then enjoy writing!

## Commands

Press `cmd-shift-P` to bring up the list of commands, and type:

- `hexo new post`   Create a new article, use `post` layout
- `hexo new page`   Create a new article, use `page` layout
- `hexo new draft`  Create a new article, use `draft` layout
- `hexo generate`   Generate static files
- `hexo deploy`     Generate static files and deploy

## Todo

- Command: `hexo publish` Publishe a draft
- Command: `hexo clean` Clean the cache file and generated files
- Test

[Hexo]: http://hexo.io/
