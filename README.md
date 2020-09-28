# md-img-paste.vim

Yet simple tool to paste images into markdown files.

## Use Case

You are editing a markdown file and have an image on the clipboard and want to paste it into the document as the text `![image_name](images_dir/image_name.png)`.

Instead of first copying it to that directory, you want to do it with a single key press in Vim. So you hooks, for example, `<leader>p` to a command `MarkdownClipboardImage`, which saves the image from the clipboard to `images_dir/image_name.png`, and inserts `![image_name](images_dir/image_name.png)` into the file.

## Installation

```
Plug 'dbakker/vim-projectroot'
Plug 'roachsinai/md-img-paste.vim'
```

## How it works

### Project Root

> The project root is the nearest ancestor directory of the current file which contains one of these directories or files: `.svn`, `.git`, `.hg`, `.root` or `.project`. If none of the parent directories contains these root markers, the directory of the current file is used as the project root. The root markers can also be configurated, see [Project Root](https://github.com/skywind3000/asyncrun.vim/wiki/Project-Root).
>
> If your current project is not in any git or subversion repository, just put an empty .root file in your project root.

### Images Root

Images root is about where to save the images and default value is identical to project root.  It could be better when you set `g:vimage_paste_config_file`, it will be replaced by its default value `.vimage_paste.json` in following explanation. Directory of nearest ancestor `.vimage_paste.json` of the editing file is images root for this file.

### Example

Think about this situation: all your notes are saved to a directory named: `Notes`:

```
.
├── Listening
│   └── .vimage_paste.json
├── Reading
│   └── .vimage_paste.json
├── .root
├── Speaking
│   ├── Chinese
│   │   └── .vimage_paste.json
│   └── .vimage_paste.json
└── Writing
```

Porject root is `Notes` and all `.vimage_paste.json` is just a blank file. Then when you editing a file under `Listening`, run command `MarkdownClipboardImage` will save image in clipboard to a **directory** under `Listening` directly, same with `Reading, Speaking and Chinese`. That means `MarkdownClipboardImage` will find the nearest ancestor `.vimage_paste.json` and save image under that directory.

If failed to find a `.vimage_paste.json`, like `Writing`, image will save to a **directory** under project root.

### What's the name of that directory to save images?

Please use `g:vimage_paste_directory_name` which must be a non-empty list of string. When saving image from clipboard, this plugin will iterate each item in `g:vimage_paste_directory_name` to check whether already has a corresponding directory (same directory name with item) under images root in order. Image will be save to the first hit directory and first item will be used if not hits.

Default value of `g:vimage_paste_directory_name` is `['.images', '.imgs', '.assets', 'images', 'imgs', 'assets', 'image', 'img', 'asset']`.

### Setting is to short

```
let g:vimage_paste_directory_name = ['images']
let g:vimage_paste_config_file = '.config.json'
nnoremap <leader>p :MarkdownClipboardImage<CR>
```

### For linux user

Install `xclip` first as this plugin gets clipboard content by running the `xclip` command.

## Acknowledgements

I'm not yet perfect at writing vim plugins but I managed to do it. Thanks to [Karl Yngve Lervåg](https://vi.stackexchange.com/users/21/karl-yngve-lerv%C3%A5g) and [Rich](https://vi.stackexchange.com/users/343/rich) for help on [vi.stackexchange.com](https://vi.stackexchange.com/questions/14114/paste-link-to-image-in-clipboard-when-editing-markdown) where they proposed a solution for my use case.
}
```
