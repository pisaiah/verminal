// Verminal - Terminal Emulator in V
module main

import iui as ui
import os.font
import os

[console]
fn main() {
	mut font_path := font.default()
	windows_term := 'C:/windows/fonts/consola.ttf'
	if os.exists(windows_term) {
		font_path = windows_term
	}

	mut win := ui.window_with_config(theme_dark(), 'Verminal', 800, 437, ui.WindowConfig{
		font_path: font_path
		font_size: 14
		ui_mode: true
	})

	mut tb := ui.tabbox(win)
	tb.set_id(mut win, 'terminal:tabs')

	mut box := create_box(win)
	tb.add_child('Verminal #0', box)
	win.add_child(tb)

	win.gg.run()
}

fn get_current_terminal(win &ui.Window) &ui.TextArea {
	mut tb := &ui.Tabbox(win.get_from_id('terminal:tabs'))
	mut kid := tb.kids[tb.active_tab][0]
	if mut kid is ui.TextArea {
		return kid
	}
	return voidptr(0)
}

fn new_tab(win &ui.Window) {
	mut tb := &ui.Tabbox(win.get_from_id('terminal:tabs'))
	mut box := create_box(win)

	name := 'Verminal #' + tb.kids.len.str()
	tb.add_child(name, box)
}
