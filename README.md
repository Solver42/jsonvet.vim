# jsonvet.vim

A one-key JSON checker for Vim, powered by [jsonvet](https://github.com/simonvanlierde/jsonvet)

Why use jsonvet.vim?

- **Speed** — Vim9 script that compiles into bytecode, uses jsonvet
- **Focus** — One key, one result. No diagnostics while you type, no squiggly underlines
- **Simplicity** — Install jsonvet and clone the repo. No package manager, no configuration.

## Requirements

- [jsonvet](https://github.com/simonvanlierde/jsonvet)
- [Vim](https://github.com/vim/vim) 9.0+

## Install

Clone the repository:
```sh
git clone https://github.com/Solver42/jsonvet.vim ~/.vim/pack/plugins/start/jsonvet.vim
```

## Update

```sh
cd ~/.vim/pack/plugins/start/jsonvet.vim && git pull
```

## Usage

- **\<Leader\>n** checks the file in the current buffer
- **:JsonCheck** does the same
- **:copen** lists everything jsonvet found, **:cnext** and **:cprev** jump between the problems

## How it works

The buffer is saved first if it has unsaved changes, then its file is checked with jsonvet. A green message means the file passed, and it starts with the type of the file: `json check successful`, `jsonc check successful`. A red message is the first error, and the cursor is moved onto it. Everything jsonvet found is also put in the quickfix list. Warnings don't fail a check: they are counted in the green message, like `json check successful (1 warning, :copen)`.

A file is checked as the type it is, and the type comes from the extension:

- `.json`, `.geojson`, `.jsonld` and `.webmanifest` are JSON, so comments and trailing commas are errors
- `.jsonc`, `.code-workspace` and `.code-snippets` are JSONC, so comments are fine and trailing commas are errors
- `.json5` and `.babelrc` are JSON5
- `.jsonl` and `.ndjson` are JSON Lines
- `.hujson` and `.jwcc` are JWCC, so comments and trailing commas are fine

For the first group and for names without a telling extension the filetype Vim picked decides, so `tsconfig.json`, which Vim calls jsonc, is checked as JSONC. This is why jsonvet's own default is not used: it checks a plain `.json` as JSON5, where comments and trailing commas pass.

It is active in buffers whose filetype is json, jsonc, json5 or jsonl, and in buffers named like the files above, whatever filetype Vim picked, so it also works if your Vim doesn't know one of them. `:JsonCheck` works in any buffer.

If the check itself fails, because jsonvet isn't installed or the file can't be read or isn't UTF-8, you get that error in red instead, never a green message. jsonvet counts columns in characters, Vim wants bytes, and a byte order mark counts as a column, so both are corrected and the cursor lands on the error even on lines with non-ASCII text.

## Configuration

Pass extra flags to jsonvet with `g:jsonvet_args` in your `.vimrc`, for example to check `.jsonc` files as JWCC so trailing commas are allowed:

```
let g:jsonvet_args = ['--dialect', 'jwcc:*.jsonc']
```

The flags come after the plugin's own `--dialect` and the last match wins, so you can change the dialect of any file with a glob. A string works too, but then the shell quoting is up to you.

The plugin passes the dialect on the command line, and command line options win over `jsonvet.toml`. To let jsonvet choose the dialect itself, from your `jsonvet.toml` and the file extension, so a plain `.json` is JSON5 again:

```
let g:jsonvet_args = ['--dialect', 'auto']
```

You can change the colors of the messages:

```
highlight JsonvetError ctermfg=203 guifg=#ff5f5f
highlight JsonvetSuccess ctermfg=114 guifg=#87d787
```

To check with another key, map it in `.vimrc`. The default `<Leader>n` is then left out:

```
nmap <F5> <Plug>(jsonvet-check)
```
