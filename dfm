#!/usr/bin/env python3

"""A script to manage your dotfiles with ease.

Author: Brooks Kindle
"""

import argparse
import os


#
# List of config files to read. The config files are formatted by key: value
# pairs. The syntax of that is as follows:
# <key1> = <value1>
# <key2> = <value2>
# Each line contains a key and a value associated with that key. The only valid
# keys allowed are those that are already defined in the CONFIG_SETTINGS
# variable.
#
# Config files are read in order, so system-wide configurations go near the
# beginning of the list while user specific configurations go near the end.
#
CONFIG_FILES = [
                '/etc/dfm.conf',
                '~/.dfm.conf',
                ]

#
# Default config settings to be used by the program. You can override values by
# specifying an alternative value to the key in a config file in the form of:
# <key> = <new_value>
# For example, suppose you wish to change the default dotfile folder that the
# program monitors. In a config file, you would add the line
#
# folder = /path/to/new/dotfile/folder
# 
# This would override the default value for the folder key.
#
CONFIG_SETTINGS = {
        'folder': '~/dotfiles/',
        }


def load_config_helper(fd):
    """Read user config settings from a single file.

    Arguments:
        fd  -   file descriptor of the config file
    """
    # the config files are small enough that we don't need to worry about the
    # memory usage of reading the entire file in at once
    for line in fd.read().splitlines():
        splitline = line.split('=')
        if len(splitline) != 2:
            print('Unknown line in config file (skipping): {}'.format(line))
            continue
        key = splitline[0].strip()
        value = splitline[1].strip()
        if key not in CONFIG_SETTINGS:
            print('Unknown setting in config file (skipping): {}'.format(key))
            continue
        CONFIG_SETTINGS[key] = value

def load_config():
    """Read user settings from a set of configuration file.

    This function loops over each file defined in the CONFIG_FILES global
    variable. For each valid file that is able to be opened, it then reads all
    of the user settings from that file and continues to the next file. If no
    config file was found, then the default settings defined in the
    CONFIG_SETTTINGS variable will be used.
    """
    for cfg_file in CONFIG_FILES:
        try:
            with open(os.path.expanduser(cfg_file)) as fd:
                load_config_helper(fd)
        except:
            continue

def main():
    """Entry point of the program"""
    #
    # Read config files
    #
    load_config()  

    #
    # Parse command line arguments.
    #
    parser = argparse.ArgumentParser(description='Manage your dotfiles')
    subparsers = parser.add_subparsers(title='subcommands',
                                       description='valid subcommands',
                                       help='additional help')
    subparsers.required = True  # require at least one command line argument
    subparsers.dest = 'command'  # require at least one command line argument

    list_parser = subparsers.add_parser('list', help='list managed files')
    add_parser = subparsers.add_parser('add', help='add a file to be tracked')
    add_parser.add_argument('dotfile')

    opts = parser.parse_args()

    #
    # Based on what arguments were given, call the appropriate function.
    #
    fptrs = {'add': lambda o:print('chosen add, dotfile={}'.format(o.dotfile)),
             'list': lambda o:print('list has been chosen! all hail list'),
             }
    fptrs[opts.command](opts)

if __name__ == '__main__':
    main()
