if exists("loaded_mdip")
    finish
endif

let g:vimage_paste_config_file = get(g:, 'vimage_paste_config_file', '.vimage_paste.json')
let g:vimage_paste_directory_name = get(g:, 'vimage_paste_directory_name', ['.images', '.imgs', '.assets', 'images', 'imgs', 'assets', 'image', 'img', 'asset'])
let s:image_tmp_name_prefix = '/tmp/vimge_paste'

" https://stackoverflow.com/questions/57014805/check-if-using-windows-console-in-vim-while-in-windows-subsystem-for-linux
function! s:IsWSL()
    let lines = readfile("/proc/version")
    if lines[0] =~ "Microsoft"
        return 1
    endif
    return 0
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
	if has_key(config_json, s:os)
		let images_dir = config_json[s:os]['images_dir']
		" string prefix to fill in link part of ![]()
		let image_link_prefix = images_dir
	else
		let image_link_prefix = g:vimage_paste_directory_name[0]
		for item in g:vimage_paste_directory_name
			if isdirectory(images_root . s:path_separator . item) == 1
				let image_link_prefix = item
				break
			endif
		endfor
		let images_dir = images_root . s:path_separator . image_link_prefix
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
		let image_path = a:images_dir . '/' . image_name . '.' . extension
		if filereadable(image_path)
			let input_prompt = 'Image ' . image_name . ' exists, input name again: '
		else
			break
		endif
	endwhile
	call system('mv ' . image_tmp_name . ' ' . image_path)

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

function! s:InputName(input_prompt)
    call inputsave()
    let name = input(a:input_prompt)
    call inputrestore()
    return name
endfunction

function! s:MarkdownClipboardImage()
    " detect os: https://vi.stackexchange.com/questions/2572/detect-os-in-vimscript
    let s:os = "Windows"
    if !(has("win64") || has("win32") || has("win16"))
        let s:os = substitute(system('uname'), '\n', '', '')
    endif
	if s:IsWSL()
		let s:os = "WSL"
	endif
	let s:path_separator = (s:os == "Windows" ? '\' : '/')

    let [images_dir, image_link_prefix] = s:SafeMakeDir()
    " image_name, used for both alt tag and image link
    let [image_name, extension] = s:SaveImage(images_dir)
    if image_name == -1
		echo "Not a image in clipboard."
        return
    else
		let image_link = image_link_prefix . s:path_separator . image_name . '.' . extension
        execute 'normal! i![' . image_name . '](' . image_link . ')'
		echom "Image saved to directory: " . images_dir
    endif
endfunction

command MarkdownClipboardImage call s:MarkdownClipboardImage()
let loaded_mdip = 1
