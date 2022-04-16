// Verminal - Terminal Emulator in V
module main

import iui as ui

fn main() {
    mut win := ui.window(theme_dark(), 'Verminal', 800, 400)

    mut box := create_box(win)
    win.add_child(box)

    win.gg.run()
}
