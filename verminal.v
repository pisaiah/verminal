// Verminal - Terminal Emulator in V
module main

import iui as ui
import os
import gx

fn create_box(win_ptr voidptr) &ui.TextArea {
	mut win := &ui.Window(win_ptr)

	path := os.real_path(os.home_dir())
	win.extra_map['path'] = path

	mut box := ui.textarea(win, ['Verminal 0.4.2', 'Copyright © 2021-2022 Isaiah.', '', path + '>'])
	box.set_id(mut win, 'vermbox')
	box.padding_y = 10
	box.code_syntax_on = false
	box.draw_event_fn = box_draw
	box.before_txtc_event_fn = before_txt_change
	box.set_bounds(0, 0, 800, 420)

	return box
}

fn box_draw(mut win ui.Window, com &ui.Component) {
	mut this := *com
	if mut this is ui.TextArea {
		this.is_selected = true

		this.caret_top = this.lines.len - 1
		line := this.lines[this.caret_top]

		size := win.gg.window_size()
		cp := win.extra_map['path']

		if this.width != size.width || this.height != size.height {
			this.width = size.width
			this.height = size.height - 24
		}

		if line.contains(cp + '>') {
			if this.caret_left < cp.len + 1 {
				this.caret_left = cp.len + 1
			}
		}
	}
}

fn before_txt_change(mut win ui.Window, tb ui.TextArea) bool {
	mut is_backsp := tb.last_letter == 'backspace'

	mut tbox := get_current_terminal(win)
	tbox.scroll_i = tbox.lines.len

	if is_backsp {
		mut txt := tb.lines[tb.caret_top]
		mut cline := txt // txt[txt.len - 1]
		mut path := win.extra_map['path']
		if cline.ends_with(path + '>') {
			return true
		}
	}

	mut is_enter := tb.last_letter == 'enter'

	if is_enter {
		mut txt := tb.lines[tb.caret_top]
		mut cline := txt // txt[txt.len - 1]
		mut path := win.extra_map['path']

		if cline.contains(path + '>') {
			mut cmd := cline.split(path + '>')[1]
			on_cmd(mut win, tb, cmd)
		}
		return true
	}
	return false
}

fn on_cmd(mut win ui.Window, box ui.TextArea, cmd string) {
	args := cmd.split(' ')

	mut tbox := get_current_terminal(win)

	if args[0] == 'cd' {
		cmd_cd(mut win, mut tbox, args)
		add_new_input_line(mut tbox)
	} else if args[0] == 'help' {
		tbox.lines << win.extra_map['verm-help']
		add_new_input_line(mut tbox)
	} else if args[0] == 'version' || args[0] == 'ver' {
		tbox.lines << 'Verminal - A terminal emulator written in V'
		tbox.lines << '\tVersion: 0.4, UI Version: ' + ui.version
		add_new_input_line(mut tbox)
	} else if args[0] == 'cls' || args[0] == 'clear' {
		tbox.lines.clear()
		tbox.scroll_i = 0
		add_new_input_line(mut tbox)
	} else if args[0] == 'font-size' {
		win.font_size = args[1].int()
		add_new_input_line(mut tbox)
	} else if args[0] == 'dira' {
		mut path := win.extra_map['path']
		cmd_dir(mut tbox, path, args)
		add_new_input_line(mut tbox)
	} else if args[0] == 'v' || args[0] == 'dir' || args[0] == 'git' {
		go cmd_exec(mut win, mut tbox, args)
	} else if args[0].len == 2 && args[0].ends_with(':') {
		win.extra_map['path'] = os.real_path(args[0])
		add_new_input_line(mut tbox)
		tbox.caret_top += 1
	} else if args[0] == 'tree' {
		path := os.real_path(win.extra_map['path'])
		go tree_cmd(path, mut tbox, 0)
	} else if args[0] == 'szip' {
		szip_cmd(args, mut tbox)
		tbox.lines << ' '
		add_new_input_line(mut tbox)
	} else if args[0] == 'terminal-height' {
		tbox.lines << win.gg.window_size().str()
		tbox.lines << ' '
		add_new_input_line(mut tbox)
	} else if args[0] == 'theme' {
		cmd_theme(mut win, mut tbox, args)
		add_new_input_line(mut tbox)
	} else if args[0] == 'new_tab' {
		new_tab(win)
	} else {
		cmd_exec(mut win, mut tbox, args)
	}

	win.extra_map['lastcmd'] = cmd
}

fn add_new_input_line(mut tbox ui.TextArea) {
	tbox.lines << tbox.win.extra_map['path'] + '>'
}

//
//	Dark Theme for a Terminal
//
pub fn theme_dark() ui.Theme {
	return ui.Theme{
		name: 'Dark Terminal'
		text_color: gx.rgb(245, 245, 245)
		background: gx.black
		button_bg_normal: gx.black
		button_bg_hover: gx.black
		button_bg_click: gx.black
		button_border_normal: gx.rgb(130, 130, 130)
		button_border_hover: gx.black
		button_border_click: gx.black
		menubar_background: gx.rgb(30, 30, 30)
		menubar_border: gx.rgb(30, 30, 30)
		dropdown_background: gx.black
		dropdown_border: gx.black
		textbox_background: gx.black
		textbox_border: gx.black
		checkbox_selected: gx.gray
		checkbox_bg: gx.black
		progressbar_fill: gx.gray
		scroll_track_color: gx.black
		scroll_bar_color: gx.gray
	}
}
