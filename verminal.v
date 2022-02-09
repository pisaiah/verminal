// Verminal - Terminal Emulator in V
//     Copyright (c) 2022 Isaiah.
//     Distributed under the MIT or the Boost Software License,
//     (see LICENSE.txt for details)
//
module main

import iui as ui
import os
import gg

const (
	show_tabs  = false
	version    = '0.1'
	addon_mode = 0
)

// const not working right in library mode.
fn set_help(mut win ui.Window) {
	help_txt := [
		'Verminal Commands:',
		'HELP           This',
		'VER            Output version string',
		'CLS            Clear the screen',
		'FONT-SIZE      Change the font size',
		'CD             Change the current directory',
		'DIR            List all contents in current directory',
		'V              Run the V compiler',
		'<OTHER>        Run with os.execute',
	]
	win.extra_map['verm-help'] = help_txt.join('\n')
}

//
// As Vide Addon
//
[export: 'on_load']
pub fn on_load(mut win ui.Window) {
	println('Verminal - Addon Mode')
	set_help(mut win)
	win.extra_map['path'] = os.real_path(win.extra_map['workspace'])
	for mut com in win.components {
		if mut com is ui.Textbox {
			create_single_box(mut win, mut com)
		}
	}
}

//
// As Standalone Terminal
//
[console]
fn main() {
	mut win := ui.window(ui.theme_dark(), 'Verminal', 800, 400)
	set_help(mut win)
	win.show_menu_bar = false
	win.font_size = 18

	mut tb := ui.tabbox(win)
	tb.set_bounds(0, 25, 800, 400)
	if show_tabs {
		tb.set_bounds(0, 25, 800, 400)
	} else {
		tb.set_bounds(0, 1, 800, 425)
	}

	win.extra_map['path'] = os.home_dir()
	create_textbox(mut win, mut tb)

	win.add_child(tb)
	win.bar = ui.menubar(win, win.theme)
	win.gg.run()
}

fn before_txt_change(mut win ui.Window, tb ui.Textbox) bool {
	mut is_backsp := tb.last_letter == 'backspace'
	if is_backsp {
		mut txt := tb.text.split_into_lines()
		mut cline := txt[txt.len - 1]
		mut path := win.extra_map['path']
		if cline.ends_with(path + '>') {
			return true
		}
	}
	return false
}

fn on_txt_change(mut win ui.Window, tb ui.Textbox) {
	mut is_enter := tb.last_letter == '\n'

	if is_enter {
		mut txt := tb.text.split_into_lines()
		mut cline := txt[txt.len - 1]
		mut path := win.extra_map['path']
		if cline.contains(path + '>') {
			mut cmd := cline.split(path + '>')[1]
			on_cmd(mut win, tb, cmd)
		}
	}
}

fn get_box(mut win ui.Window) &ui.Textbox {
	if addon_mode == 0 {
		for mut com in win.components {
			if mut com is ui.Tabbox {
				mut tab := com.kids[com.active_tab]
				mut tbox := tab[0]
				if mut tbox is ui.Textbox {
					return tbox
				}
			}
		}
	} else {
		for mut com in win.components {
			if mut com is ui.Textbox {
				return com
			}
		}
	}
	mut un := ui.textbox(win, 'Oh no; Could not find')
	return un
}

fn on_cmd(mut win ui.Window, box ui.Textbox, cmd string) {
	args := cmd.split(' ')

	mut tbox := get_box(mut win)

	if args[0] == 'cd' {
		cmd_cd(mut win, mut tbox, args)
	} else if args[0] == 'help' {
		tbox.text = tbox.text + win.extra_map['verm-help']
	} else if args[0] == 'version' || args[0] == 'ver' {
		tbox.text = tbox.text + 'Verminal version ' + version
	} else if args[0] == 'cls' || args[0] == 'clear' {
		tbox.text = ''
	} else if args[0] == 'exec' {
		mut res := os.execute(args.join(' ').replace_once('exec ', ''))
		tbox.text = tbox.text + res.output
	} else if args[0] == 'font-size' {
		win.font_size = args[1].int()
	} else if args[0] == 'dira' {
		mut path := win.extra_map['path']
		cmd_dir(mut tbox, path, args)
	} else if args[0] == 'v' || args[0] == 'dir' || args[0] == 'git' {
		cmd_exec(mut win, mut tbox, args)
	} else if args[0].len == 2 && args[0].ends_with(':') {
		win.extra_map['path'] = args[0]
	} else {
		cmd_exec(mut win, mut tbox, args)
	}
	tbox.text = tbox.text + '\n' + win.extra_map['path'] + '>'
	len := tbox.text.split_into_lines().len
	if tbox.scroll_i > len {
		tbox.scroll_i += 100
	}

	win.extra_map['lastcmd'] = cmd
}

fn on_box_draw(mut win ui.Window, mut box ui.Component) {
	if mut box is ui.Textbox {
		if !box.is_selected {
			return
		}

		mut txt := box.text.split_into_lines()
		if box.carrot_top != (txt.len - 1) {
			trimmed := box.text.trim_space()
			if box.carrot_top == (txt.len - 2) && trimmed.ends_with('>') {
				if 'lastcmd' in win.extra_map {
					box.text = box.text.trim_space() + win.extra_map['lastcmd'].trim_space()
					box.carrot_top = txt.len - 1
					txt = box.text.split_into_lines()
					box.carrot_left = txt[txt.len - 1].len
				}
			}
		}

		txt = box.text.split_into_lines()
		mut cline := txt[txt.len - 1]

		box.carrot_top = txt.len - 1
		if cline.contains('>') {
			mut min_left := cline.split('>')[0].len + 1
			if box.carrot_left < min_left {
				box.carrot_left = min_left
			}
		}

		if addon_mode == 0 {
			size := gg.window_size()
			mut h := size.height
			if win.show_menu_bar {
				h -= 25
			}
			if show_tabs {
				h -= 25
			}
			ui.set_size(mut box, size.width - 2, h)

			for mut kid in win.components {
				if mut kid is ui.Tabbox {
					if show_tabs {
						ui.set_size(mut kid, size.width, size.height + 25)
					} else {
						ui.set_size(mut kid, size.width, size.height)
					}
				}
			}
		}
	}
}

fn create_single_box(mut win ui.Window, mut box ui.Textbox) {
	// mut box := ui.textbox(win, 'Verminal - Terminal Emulator in V\nCopyright © 2022 Isaiah.\n\nC:\\Users>')
	box.text = 'Verminal - Terminal Emulator in V\nCopyright © 2022 Isaiah.\n\n' + win.extra_map['path'] + '>'
	box.text_change_event_fn = on_txt_change
	box.before_txtc_event_fn = before_txt_change
	box.draw_event_fn = on_box_draw
	// return box
}

fn create_textbox(mut win ui.Window, mut tb ui.Tabbox) {
	mut box := ui.textbox(win, 'Verminal - Terminal Emulator in V\nCopyright © 2022 Isaiah.\n\n' + win.extra_map['path'] + '>')

	if show_tabs {
		box.set_bounds(1, 1, 798, 398 - 25)
	} else {
		box.set_bounds(1, 1, 798, 398)
	}
	box.text_change_event_fn = on_txt_change
	box.before_txtc_event_fn = before_txt_change
	box.draw_event_fn = on_box_draw
	tb.add_child('Tab A', box)
}
