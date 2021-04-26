if exists("g:git_add_with_image_key")
    silent! exe 'nnoremap <silent> ' . g:git_add_with_image_key . ' :GitAddWithImage<CR>'
endif
