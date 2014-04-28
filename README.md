# Atom-Hexo

> [Hexo] for the Atom Editor.

Provides [Hexo] `new`, `generate`, `deploy`, `publish`, `clean` commands in the Atom Editor.

![A screenshot of Atom-Hexo](http://ww3.sinaimg.cn/large/65cc6c38gw1efvmat8ya8g20vj0kmqjx.gif)

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
- hexo list drafts  # Lists drafts, and open the selectd
- hexo publish      # Publish a draft
- hexo generate     # Generate static files
- hexo deploy       # Generate static files and deploy
- hexo clean        # Clean the cache file and generated files
```

## Todo

```bash
- [] Test
```

[Hexo]: http://hexo.io/
