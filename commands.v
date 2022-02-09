module main

import iui as ui
import os

fn cmd_cd(mut win ui.Window, mut tbox ui.Textbox, args []string) {
	mut path := win.extra_map['path']
    if args.len == 1 {
        tbox.text = tbox.text + path
        return
    }
    
	if args[1] == '..' {
		path = path.substr(0, path.replace('\\', '/').last_index('/') or {0})
	} else {
		if os.is_abs_path(args[1]) {
			path = os.real_path(args[1])
		} else {
			path = os.real_path(path + '\\' + args[1])
		}
	}
	if os.exists(path) {
		win.extra_map['path'] = path
	} else {
		tbox.text = tbox.text + 'Cannot find the path specified: ' + path
	}
}

fn cmd_dir(mut tbox ui.Textbox, path string, args []string) {
	mut ls := os.ls(os.real_path(path)) or { [''] }
	mut txt := ' Directory of ' + path + '\n\n'
	for file in ls {
		txt = txt + '\t' + file + '\n'
	}
    //os.file_last_mod_unix(os.real_path(path + '/' + file)).str()
    tbox.text = tbox.text + txt
}

fn cmd_v(mut tbox ui.Textbox, args []string) {
	mut pro := os.execute('cmd /min /c ' + args.join(' '))
	tbox.text = tbox.text + pro.output.trim_space()
}

fn cmd_exec(mut win ui.Window, mut tbox ui.Textbox, args []string) {
    mut pro := os.new_process('cmd')
    
    mut argsa := ['/min', '/c', 'cd', win.extra_map['path'], '&&', 'C:', '&&', args.join(' ')]
    pro.set_args(argsa)
    
    pro.set_redirect_stdio() 
    pro.run()
    
    for pro.is_alive() {
        mut out := pro.stdout_slurp()
        tbox.text = tbox.text + out.trim_space()
        //println('OUT: ' + out)
    }
}