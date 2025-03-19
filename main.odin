package main

import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:slice"
import "core:strings"

println :: fmt.println
printfln :: fmt.printfln

HELP_TEXT :: `
Usage: ssh-change [(list | ls) | help | {config-to-change}]

- help: Prints help info
- list | ls: Lists all detected configs in your ssh config file
- {config-to-change}: Changes your ssh config file to uncomment {config-to-change}, and comments all the other detected configs
`


Config :: struct {
	start_line: int,
	end_line:   int,
	name:       string,
}

source_file_path: string

// FIXME: the script adds an empty line at the beginning
main :: proc() {
	if len(os.args) != 2 {
		println(HELP_TEXT)
		os.exit(2)
	}

	if os.args[1] == "help" {
		println(HELP_TEXT)
		os.exit(0)
	}

	get_source_file_path()

	configs := read_configs()

	if os.args[1] == "list" || os.args[1] == "ls" {
		if len(configs) == 0 {
			println("No configs detected.")
		} else {
			println("Detected configs: \n")
			for c in configs {
				println("- ", c.name)
			}
		}
		os.exit(0)
	}

	config_to_apply := get_config_to_apply(configs)

	apply_config(config_to_apply, configs)
}

get_source_file_path :: proc() {
	home_dir := os.get_env("HOME")

	source_strings: [2]string

	source_strings[0] = home_dir
	source_strings[1] = "/.ssh/config"

	source_file_path = strings.concatenate(source_strings[:])
}

apply_config :: proc(config: Config, all_configs: []Config) {
	lines_to_comment: [dynamic]int
	lines_to_uncomment: [dynamic]int

	for c in all_configs {
		if c.name == config.name {
			for i in c.start_line ..= c.end_line {
				append(&lines_to_uncomment, i)
			}
		} else {
			for i in c.start_line ..= c.end_line {
				append(&lines_to_comment, i)
			}
		}
	}

	data, ok := os.read_entire_file(source_file_path)
	defer delete(data)

	text := string(data)
	lines := strings.split_lines(text)

	if len(lines) == 0 {
		println("Cannot run the script on an empty file.")
		os.exit(2)
	}

	line_index := 0
	for line in lines {
		defer line_index += 1

		if slice.contains(lines_to_comment[:], line_index) && !strings.starts_with(line, "#") {
			lines[line_index] = strings.concatenate({"# ", line})
			continue
		}

		if slice.contains(lines_to_uncomment[:], line_index) && strings.starts_with(line, "#") {
			// Also remove the whitespace if it exists
			if strings.starts_with(line, "# ") {
				lines[line_index] = line[2:]
			} else {
				lines[line_index] = line[1:]
			}

			continue
		}
	}


	new_text := concat_array_slice(lines)

	write_ok := os.write_entire_file(source_file_path, transmute([]u8)new_text)

	if write_ok {
		printfln("Successfully applied the '%s' config.", config.name)
	} else {
		printfln("Error writing to %s.", source_file_path)
	}
}

concat_array_slice :: proc(slice: []string) -> string {
	final_string := slice[0]

	for i in 1 ..< len(slice) {
		line := slice[i]
		final_string = strings.concatenate({final_string, "\n", line})
	}

	return final_string
}

get_config_to_apply :: proc(configs: []Config) -> Config {
	for c in configs {
		if c.name == os.args[1] {
			return c
		}
	}

	printfln("No config with the name '%s' found.", os.args[1])
	os.exit(2)
}

read_configs :: proc() -> []Config {
	configs: [dynamic]Config

	data, ok := os.read_entire_file(source_file_path)
	defer delete(data)

	if !ok {
		println("Failed to read ", source_file_path)
		os.exit(2)
	}

	text := string(data)

	current_config := ""
	line_index := 0
	start_line := 0

	for line in strings.split_lines_iterator(&text) {
		defer line_index += 1

		if line == "" {
			continue
		}

		if strings.starts_with(line, "# > ssh-change - ") {
			split := strings.split(line, "# > ssh-change - ")
			if len(split) > 1 {
				start_line = line_index + 1
				current_config = split[1]
			}
		}

		if strings.starts_with(line, "# > ssh-change-end") {
			new_config := Config {
				start_line = start_line,
				end_line   = line_index - 1,
				name       = current_config,
			}

			if new_config.start_line >= new_config.end_line {
				printfln(
					"Error: Invalid config: start_line: %s; end_line: %s -> start_line needs to be lower than end_line.",
				)
				os.exit(2)
			}

			append(&configs, new_config)
			current_config = ""
		}
	}

	return configs[:]
}
