if exists("loaded_mdip")
    finish
endif

let g:vimage_paste_config_file = get(g:, 'vimage_paste_config_file', '.vimage_paste.json')
let g:vimage_paste_directory_name = get(g:, 'vimage_paste_directory_name', ['.images', '.imgs', '.assets', 'images', 'imgs', 'assets', 'image', 'img', 'asset'])
let s:image_tmp_name_prefix = '/tmp/vimge_paste'
let g:vimage_paste_how_insert_link = get(g:, 'vimage_paste_how_insert_link', 'A')

" https://stackoverflow.com/questions/57014805/check-if-using-windows-console-in-vim-while-in-windows-subsystem-for-linux
function! s:IsWSL()
    let lines = readfile("/proc/version")
    if lines[0] =~ "Microsoft"
        return 1
    endif
    return 0
endfunction

function! s:DetectOS()
    " detect os: https://vi.stackexchange.com/questions/2572/detect-os-in-vimscript
    let s:os = "Windows"
    if !(has("win64") || has("win32") || has("win16"))
        let s:os = s:RemoveTrailingChars(system('uname'), '\n')
    endif
	if s:IsWSL()
		let s:os = "WSL"
	endif
	let s:path_separator = (s:os == "Windows" ? '\' : '/')
endfunction

function! s:GetRootDirs()
	let project_root_dir = ProjectRootGuess()

	let prev_rootmarkers = g:rootmarkers
	let g:rootmarkers = [g:vimage_paste_config_file]
	let images_root_dir = ProjectRootGuess()
	let g:rootmarkers = prev_rootmarkers

	let chars_count = len(project_root_dir)
	" config_file exists in images_root_dir and images_root_dir is subdirectory of project_root_dir
	if !empty(glob(images_root_dir . s:path_separator . g:vimage_paste_config_file)) &&
		\ (chars_count < len(images_root_dir) && images_root_dir[:chars_count] == project_root_dir . s:path_separator)
			return images_root_dir
	endif
	return project_root_dir
endfunction

function! s:SafeMakeDir()
	let images_root = s:GetRootDirs()
	let config_file_absolute_path = images_root . s:path_separator . g:vimage_paste_config_file
	" maybe config_file exists in project_root_dir
	let config_json = {}
	if !empty(glob(config_file_absolute_path))
		let json_parsed = json_decode(join(readfile(config_file_absolute_path), ''))
		if type(json_parsed) == 4 | let config_json = json_parsed | endif
	endif
	if has_key(config_json, 'images_dir')
		let images_dir = config_json['images_dir']
		" string prefix to fill in link part of ![]()
		let image_link_prefix = s:RemoveTrailingChars(images_dir, s:path_separator)
		if images_dir[0] == '.'
			let images_dir = s:RemoveTrailingChars(system('realpath ' . expand("%:p:h") . s:path_separator . image_link_prefix), '\n')
		endif
	else
		let image_dir_name = g:vimage_paste_directory_name[0]
		for item in g:vimage_paste_directory_name
			if isdirectory(images_root . s:path_separator . item) == 1
				let image_dir_name = item
				break
			endif
		endfor
		let images_dir = images_root . s:path_separator . image_dir_name
		let image_link_prefix = s:RemoveTrailingChars(system('realpath --relative-to=' . expand("%:p:h") . ' ' . images_dir), '\n')
	endif

    if !isdirectory(images_dir)
        call mkdir(images_dir, "p")
    endif

	return [fnameescape(images_dir), image_link_prefix]
endfunction

function! s:SaveImageLinux(images_dir) abort
    let targets = filter(
                \ systemlist('xclip -selection clipboard -t TARGETS -o'),
                \ 'v:val =~# ''image/''')

    if empty(targets) | return [-1, 0] | endif

    if index(targets, "image/png") >= 0
        " Use PNG if available
        let mimetype = "image/png"
        let extension = "png"
    else
        " Fallback
        let mimetype = targets[0]
        let extension = split(mimetype, '/')[-1]
    endif

	let image_tmp_name = s:image_tmp_name_prefix . string(rand() % 10000)
    call system(printf('xclip -selection clipboard -t %s -o > %s',
                \ mimetype, image_tmp_name))
	let input_prompt = 'Image name: '
	while v:true
		let image_name = s:InputName(input_prompt)
		if image_name == '' | return [-2, 0] | endif
		" 'f name', f\ name -> fname
		if image_name[0] == '''' || image_name[0] == '""'
			let image_name = image_name[1: -2]
		endif
		let image_name = substitute(image_name, '\\ ', ' ', 'g')

		let image_path = a:images_dir . '/' . image_name . '.' . extension
		if filereadable(image_path)
			let input_prompt = 'Image ' . image_name . ' exists, input name again: '
		else
			break
		endif
	endwhile
	call system('mv ' . image_tmp_name . ' ' . fnameescape(image_path))

    return [image_name, extension]
endfunction

function! s:SaveImage(images_dir)
    if s:os == "Linux"
        return s:SaveImageLinux(a:images_dir)
    elseif s:os == "WSL"
            return s:SaveImageWSL(a:images_dir)
    elseif s:os == "Darwin"
        return s:SaveImageMacOS(a:images_dir)
    elseif s:os == "Windows"
        return s:SaveImageWin32(a:images_dir)
    endif
endfunction

function! s:DeleteImageLinux()
	let l:cur_line = getline(".")
	let l:matches = filter(matchlist(l:cur_line, '\[\(.\{-}\)\](\(.\{-}\))'), 'v:val !=# ""')
	if len(l:matches) < 2
		echom 'Not an image tag line.'
		return
	endif
	let l:relative_path = l:matches[-1]
	let l:space_equal_pos = strridx(l:relative_path, ' =')
	if l:space_equal_pos != -1
		let l:space_equal_pos -= 1
	endif
	let l:image_path = s:RemoveTrailingChars(system('cd ' . expand("%:p:h") . ' && realpath ' . l:relative_path[0: l:space_equal_pos]), '\n')
	if filereadable(l:image_path)
		let l:choice = confirm('Delete image: ' . l:matches[-1] . '?', "&Yes\n&No", 2)
		if l:choice == 1
			call delete(l:image_path)
			let l:image_tag_start = stridx(l:cur_line, l:matches[0]) - 1
			let l:image_tag_end = stridx(l:cur_line, l:matches[0]) + len(l:matches[0])
			let l:new_line = (l:image_tag_start == 0? '' : l:cur_line[:l:image_tag_start - 1]) . l:cur_line[l:image_tag_end:]
			call setline(line("."), l:new_line)
		else
			echo 'Quit image delete operation.'
		endif
	else
		echom 'File: ' . l:image_path . ' not exists.'
	endif
endfunction

function! s:DeleteImage()
    if s:os == "Linux"
        return s:DeleteImageLinux()
    elseif s:os == "WSL"
            return s:DeleteImageWSL()
    elseif s:os == "Darwin"
        return s:DeleteImageMacOS()
    elseif s:os == "Windows"
        return s:DeleteImageWin32()
    endif
endfunction

function! s:InputName(input_prompt)
    call inputsave()
    let name = input(a:input_prompt)
    call inputrestore()
    return name
endfunction

function! s:RemoveTrailingChars(target, trailing)
	return substitute(a:target, a:trailing . '$', '', '')
endfunction

function! s:MarkdownClipboardImage()
    let [images_dir, image_link_prefix] = s:SafeMakeDir()
    " image_name, used for both alt tag and image link
    let [image_name, extension] = s:SaveImage(images_dir)
    if type(image_name) == 1
		let image_link = image_link_prefix . s:path_separator . fnameescape(image_name) . '.' . extension
        execute 'normal! ' . g:vimage_paste_how_insert_link . '![' . image_name . '](' . image_link . ')'
		echom "Image saved to: " . images_dir . s:path_separator . image_name . '.' . extension
	elseif image_name == -1
		echo "Not a image in clipboard."
    endif
endfunction

function! s:GitAddWithImage()
    let l:line_start = 0
    let l:line_end = line("$")
    let [l:images_dir, l:image_link_prefix] = s:SafeMakeDir()
    let l:imgs = []
    for linenum in range(l:line_start, l:line_end)
        let l:line = getline(linenum)
        let l:url=matchlist(l:line, '!\[.*\](.*\' . g:vimage_paste_directory_name[0] . '\(.*\))')
        if !empty(l:url)
            call add(l:imgs, l:images_dir . l:url[1])
        endif
    endfor
	if exists(":Git")
		execute 'Git add % ' . join(l:imgs, ' ')
	else
		call system("git add " . expand("%") . ' ' . join(l:imgs, ' '))
	endif
endfunction

command MarkdownClipboardImage call s:MarkdownClipboardImage()
command MarkdownDeleteImage call s:DeleteImage()
command GitAddWithImage call s:GitAddWithImage()
call s:DetectOS()
let loaded_mdip = 1
