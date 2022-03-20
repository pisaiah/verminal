// Verminal - Terminal Emulator in V
module main

import iui as ui
import os
import gx

fn create_box(win_ptr voidptr) &ui.TextEdit {
    mut win := &ui.Window(win_ptr)
    
        path := os.real_path(os.home_dir())
    win.extra_map['path'] = path

    
    mut box := ui.textedit(win, 'Verminal 0.3\nCopyright © 2021-2022 Isaiah.\n\n' + path + '>')
    box.set_id(mut win, 'vermbox')
    box.padding_y = 10
    box.code_syntax_on = false
    box.draw_line_numbers = false
    box.draw_event_fn = box_draw
    box.before_txtc_event_fn = before_txt_change
    box.set_bounds(0, 0, 800, 400)

    return box
}

fn box_draw(mut win ui.Window, com &ui.Component) {
    mut this := *com
    if mut this is ui.TextEdit {
        this.carrot_top = this.lines.len - 1
        line := this.lines[this.carrot_top]

        size := win.gg.window_size()
        cp := win.extra_map['path']

        if this.width != size.width || this.height != size.height {
            this.width = size.width
            this.height = size.height
        }

        if line.contains(cp + '>') {
            if this.carrot_left < cp.len + 1 {
                this.carrot_left = cp.len + 1
            }
        }
    }
}

fn before_txt_change(mut win ui.Window, tb ui.TextEdit) bool {
	mut is_backsp := tb.last_letter == 'backspace'

	if is_backsp {
		mut txt := tb.lines[tb.carrot_top]
		mut cline := txt//txt[txt.len - 1]
		mut path := win.extra_map['path']
		if cline.ends_with(path + '>') {
			return true
		}
	}

	mut is_enter := tb.last_letter == 'enter'

	if is_enter {
		mut txt := tb.lines[tb.carrot_top]
		mut cline := txt //txt[txt.len - 1]
		mut path := win.extra_map['path']

		if cline.contains(path + '>') {
			mut cmd := cline.split(path + '>')[1]
            on_cmd(mut win, tb, cmd)
		}
		return true
	}
	return false
}

fn on_cmd(mut win ui.Window, box ui.TextEdit, cmd string) {
	args := cmd.split(' ')

	mut tbox := &ui.TextEdit(win.get_from_id('vermbox'))//(mut win)

	if args[0] == 'cd' {
		cmd_cd(mut win, mut tbox, args)
		add_new_input_line(mut tbox)
	} else if args[0] == 'help' {
		tbox.lines << win.extra_map['verm-help']
		add_new_input_line(mut tbox)
	} else if args[0] == 'version' || args[0] == 'ver' {
		tbox.lines << 'Verminal - A terminal emulator written in V'
        tbox.lines << '\tVersion: 0.3'
        tbox.lines << '\tUI Version: ' + ui.version
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
		tbox.carrot_top += 1
	} else {
		cmd_exec(mut win, mut tbox, args)
	}

	win.extra_map['lastcmd'] = cmd
}

fn add_new_input_line(mut tbox ui.TextEdit) {
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
