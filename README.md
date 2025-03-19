# ssh-change

This is a small utility script to comment / uncomment some ssh config from your .ssh/config file. This is useful in the case where you have two ssh keys for the same domain, and you don't want to go and comment / uncomment them manually every time you need to push from another account.

## Installation

1. Grab it from the releases tab

or

2. Build it with the odin compiler. Just install the odin compiler and run `odin build .` in the repo's directory.

## Usage:

ssh-change [(list | ls) | help | {config-to-change}]

- help: Prints help info
- list | ls: Lists all detected configs in your ssh config file
- {config-to-change}: Changes your ssh config file to uncomment {config-to-change}, and comments all the other detected configs

### Important:

For this script to work, the lines you want this script to comment / uncomment need to be delimited with comments the following way:

```sh

# > ssh-change - personal

Host some-of-my-hosts.com
    HostName some-of-my-hosts.com
    IdentityFile ~/.ssh/host_personal

# > ssh-change-end

# > ssh-change - work

Host some-of-my-hosts.com
    HostName some-of-my-hosts.com
    IdentityFile ~/.ssh/host_work

# > ssh-change-end


```

To begin a section in the file, write `# > ssh-change - {your-config-name}`, and to end the section write `# > ssh-change-end`. The structure of the comments needs to be exactly as exemplified here.
