# Atom-Hexo

> [Hexo] for the Atom Editor.

Provides [Hexo] `new`, `generate`, `deploy` commands in the Atom Editor.

![A screenshot of Atom-Hexo](http://ww1.sinaimg.cn/large/65cc6c38gw1ef1lml8dtgg20vj0kmwn5.jpg)

## Install

```bash
apm install atom-hexo
```

You can also install `atom-hexo` by going to the `Packages` section on left hand side of the Settings view (`cmd-,`).

## Usage

Open your favorite terminal, change to your Hexo blog directory, and type `atom` to open the folder as root project. Then use Atom to enjoy writing!

## Commands

Press `cmd-shift-P` to bring up the list of commands, and type:

```bash
- hexo new post     # Create a new article, use `post` layout
- hexo new page     # Create a new article, use `page` layout
- hexo new draft    # Create a new article, use `draft` layout
- hexo generate     # Generate static files
- hexo deploy       # Generate static files and deploy
```

## Todo

```bash
- [] Command: `hexo publish`  #Publish a draft
- [] Command: `hexo clean`    #Clean the cache file and generated files
- [] Test
```

[Hexo]: http://hexo.io/
