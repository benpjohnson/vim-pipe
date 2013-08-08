nnoremap <silent> <LocalLeader>r :%call VimPipe()<CR>
vnoremap <silent> <LocalLeader>r :call VimPipe()<CR>

function! VimPipe() range " {
	" Save local settings.
	let saved_unnamed_register = @@
	let switchbuf_before = &switchbuf
	set switchbuf=useopen

	" Lookup the parent buffer.
	if exists("b:vimpipe_parent")
		let l:parent_buffer = b:vimpipe_parent
	else
		let l:parent_buffer = bufnr( "%" )
	endif

	" Create a new output buffer, if necessary.
	if ! exists("b:vimpipe_parent")
		let bufname = bufname( "%" ) . " [VimPipe]"
		let vimpipe_buffer = bufnr( bufname )

		if vimpipe_buffer == -1
			let vimpipe_buffer = bufnr( bufname, 1 )

			" Close-the-window mapping.
			execute "nnoremap \<buffer> \<silent> \<LocalLeader>p :bw " . vimpipe_buffer . "\<CR>"

			" Split & open.
			let split_command = "sbuffer " . vimpipe_buffer
			if &splitright
				let split_command = "vert " . split_command
			endif
			silent execute split_command

			" Set some defaults.
			call setbufvar(vimpipe_buffer, "&swapfile", 0)
			call setbufvar(vimpipe_buffer, "&buftype", "nofile")
			call setbufvar(vimpipe_buffer, "&bufhidden", "wipe")
			call setbufvar(vimpipe_buffer, "vimpipe_parent", l:parent_buffer)
			call setbufvar(vimpipe_buffer, "&filetype", getbufvar(l:parent_buffer, 'vimpipe_filetype'))

			" Close-the-window mapping.
			nnoremap <buffer> <silent> <LocalLeader>p :bw<CR>
		else
			silent execute "sbuffer" vimpipe_buffer
		endif

		let l:parent_was_active = 1
	endif

	" Display a "Running" message.
	silent! execute ":1,2d _"
	silent call append(0, ["# Running... ",""])
	redraw

	" Clear the buffer.
	execute ":%d _"

	" Lookup the vimpipe command from the parent.
	let l:vimpipe_command = getbufvar( b:vimpipe_parent, 'vimpipe_command' )

	" Call the pipe command, or give a hint about setting it up.
	if empty(l:vimpipe_command)
		silent call append(0, ["", "# See :help vim-pipe for setup advice."])
	else
		let l:parent_contents = getbufline(l:parent_buffer, 0, "$")
		call append(line('0'), l:parent_contents)

		" Generate Ex expression for the selected range
		let range = a:firstline . "," . a:lastline

		let l:start = reltime()
		silent execute ":" . range . "!" . l:vimpipe_command
		let l:duration = reltimestr(reltime(start))
		silent call append(0, ["# Pipe command took:" . duration . "s", ""])
	endif

	" Add the how-to-close shortcut.
	let leader = exists("g:maplocalleader") ? g:maplocalleader : "\\"
	silent call append(0, "# Use " . leader . "p to close this buffer.")

	" Go back to the last window.
	if exists("l:parent_was_active")
		execute "normal! \<C-W>\<C-P>"
	endif

	" Restore local settings.
	let &switchbuf = switchbuf_before
	let @@ = saved_unnamed_register
endfunction " }

" vim: set foldmarker={,} foldlevel=1 foldmethod=marker:
