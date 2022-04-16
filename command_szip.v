// Verminal - Terminal Emulator in V
module main

import iui as ui
import os
import szip

fn szip_cmd(args []string, mut tbox ui.TextArea) {
    if args.len == 1 {
        tbox.lines << 'szip: try "szip help" for more information'
        return
    }
    if args[1] == 'help' {
        tbox.lines << 'Usage: szip <function> [arguments]'
        tbox.lines << 'szip extract [file] [dir] \t - Extract a zip file to directory using V\'s szip'
        return
    }
    if args[1] == 'extract' {
        if args.len < 4 {
            tbox.lines << 'Usage: szip extract <file> <dir>'
            return
        }
        
        file := args[2]
        dir := args[3]

        if !os.exists(file) || !os.exists(dir) {
            tbox.lines << 'Zip file or directory specified does not exist'
            return
        }

        tbox.lines << ' Extracting... '
        res := extract_zip_to_dir(file, dir) or { return }
        tbox.lines << 'Result: ' + res.str()
    }
}

// Fixed version of szip.extract_zip_to_dir
pub fn extract_zip_to_dir(file string, dir string) ?bool {
	mut zip := szip.open(file, .best_speed, .read_only) or { panic(err) }
	total := zip.total() or { return false }
	for i in 0 .. total {
		zip.open_entry_by_index(i) or {}
		do_to := os.real_path(os.join_path(dir, zip.name()))

		os.mkdir_all(os.dir(do_to)) or { println(err) }
		os.write_file(do_to, '') or {}

		if os.is_dir(do_to) {
			continue
		}

		zip.extract_entry(do_to) or {
		}
	}
	return true
}