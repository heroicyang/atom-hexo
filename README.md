# Atom-Hexo

> [Hexo] for the Atom Editor.

Provides [Hexo] `new`, `generate`, `deploy`, `publish`, `clean` commands in the Atom Editor.

## Install

```bash
apm install atom-hexo
```

You can also install `atom-hexo` by going to the `Packages` section on left hand side of the Settings view (`cmd-,`).

## Usage

- Open your Hexo blog folder with the `atom /path/to/your hexo folder` command
- Or set the `Atom-Hexo` `Current Working Directory` config on the Settings view, you can use `Atom-Hexo` anywhere, once and for all

**Enjoy writing!**

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
