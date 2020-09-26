# md-img-paste.vim

Yet simple tool to paste images into markdown files.

## Use Case

You are editing a markdown file and have an image on the clipboard and want to paste it into the document as the text `![image_name](images_dir/image_name.png)`.

Instead of first copying it to that directory, you want to do it with a single key press in Vim. So you hooks ,for example, `<leader>p` to a command `MarkdownClipboardImage`, which saves the image from the clipboard to the location `images_dir/image_name.png`, and inserts `![image_name](images_dir/image_name.png)` into the file.

## Installation

```
Plug 'skywind3000/asyncrun.vim'
Plug 'roachsinai/md-img-paste.vim'
```

## Project Root

> The project root is the nearest ancestor directory of the current file which contains one of these directories or files: `.svn`, `.git`, `.hg`, `.root` or `.project`. If none of the parent directories contains these root markers, the directory of the current file is used as the project root. The root markers can also be configurated, see [Project Root](https://github.com/skywind3000/asyncrun.vim/wiki/Project-Root).
>
> If your current project is not in any git or subversion repository, just put an empty .root file in your project root.

## Configuration

### Save to absolute path

If you want to save images an absolute path, not under project root, `g:vimage_paste_config_file` (default value: `.vimage_paste.json`) is provided to support this. The config file under porject root must be a json file has a field named `images_dir`.

### Save under project root

Please use `g:vimage_paste_directory_name` which must be a non-empty list of string. When saving image from clipboard, This plugin will check each item in `g:vimage_paste_directory_name` whether already has a corresponding directory (same directory name with item) under project root in order. Image will be save to the first hit directory and first item will be used if not hits.

Default value of `g:vimage_paste_directory_name` is `['images', 'imgs', 'assets', 'image', 'img', 'asset']`.

If both `g:vimage_paste_config_file` and `g:vimage_paste_directory_name` are set (see example below), `g:vimage_paste_config_file` will be used to config where to save image.

### Example

```
let g:vimage_paste_directory_name = ['images']
let g:vimage_paste_config_file = '.config.json'
nnoremap <leader>p :MarkdownClipboardImage<CR>
```

Content in `g:vimage_paste_config_file` could be:

```
{
    "images_dir": "/home/roach/Pictures/imgs"
}
```

### For linux user

Install `xclip` first as this plugin gets clipboard content by running the `xclip` command.

## Acknowledgements

I'm not yet perfect at writing vim plugins but I managed to do it. Thanks to [Karl Yngve Lervåg](https://vi.stackexchange.com/users/21/karl-yngve-lerv%C3%A5g) and [Rich](https://vi.stackexchange.com/users/343/rich) for help on [vi.stackexchange.com](https://vi.stackexchange.com/questions/14114/paste-link-to-image-in-clipboard-when-editing-markdown) where they proposed a solution for my use case.
