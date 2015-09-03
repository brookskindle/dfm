#!/usr/bin/env python3

"""A script to manage your dotfiles with ease.

Author: Brooks Kindle
"""

import argparse
import json
import os
import pwd
import shutil


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
# If you intend to modify or edit the default value for a config setting, make
# sure to also add or modify the appropriate entry in the CONFIG_VALIDATION
# variable.
#
CONFIG_SETTINGS = {
        'folder': '~/dotfiles/',
        'whitelist': 'dfm.whitelist',
        }

#
# Validation checks for configuration settings. Each key in this dictionary
# should also be a key in the CONFIG_SETTINGS variable. Each value in this
# dictionary is a function to validate the correctness of the given
# configuration variable value. 
#
CONFIG_VALIDATION = {
        'folder': lambda path: os.path.exists(os.path.expanduser(path)),
        'whitelist': lambda fname: True,
        }


def validate_config_settings():
    """Makes sure that each config item contains a correct value.

    This function will only properly return if none of the settings in
    CONFIG_SETTINGS contain invalid values. If this is not true, then an error
    message will be printed and exit will be called. We can't really continue
    if there are errors in our config.
    """
    should_exit = False
    for setting, value in CONFIG_SETTINGS.items():
        if CONFIG_VALIDATION[setting](value) == False:
            # This configuration value isn't correct
            print("Error while processing configuration value. "
                  "{} : {}".format(setting, value))
            should_exit = True
    if should_exit:
        exit(1)


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

def add_command(opts):
    """Runs the add command

    Arguments:
        opts    -   command line options
    """
    whitelist_file = CONFIG_SETTINGS['whitelist']
    whitelist_path = os.path.join(CONFIG_SETTINGS['folder'], whitelist_file)
    dotfiles = {}
    try:
        with open(os.path.expanduser(whitelist_path)) as fd:
            text = fd.read()
            dotfiles = json.loads(text)  # create dictionary from json file
    except:
        pass  # no files are being monitored
    new_dotfile = opts.dotfile
    filename = os.path.basename(new_dotfile)
    dotfile_path = os.path.abspath(os.path.expanduser(new_dotfile))
    if filename in dotfiles:
        print('{} is already being monitored'.format(filename))
    else:
        try:
            print("dotfile_path={}\nCONFIG_SETTINGS={}".format(dotfile_path,
                                                    CONFIG_SETTINGS['folder']))
            shutil.copy(dotfile_path,
                        os.path.expanduser(CONFIG_SETTINGS['folder']))
            # compress home path for portability to other users
            home_dir = pwd.getpwuid(os.getuid()).pw_dir
            dotfile_path = "~" + dotfile_path[len(home_dir):]
            dotfiles[filename] = dotfile_path
            with open(os.path.expanduser(whitelist_path), 'w') as fd:
                json.dump(dotfiles, fd)
        except IOError as err:
            print(err)

def list_command(opts):
    """Runs the list command

    Arguments:
        opts    -   command line options
    """
    whitelist = 'dfm.whitelist'  # json file containing a list tracked files
    whitelist_path = os.path.join(CONFIG_SETTINGS['folder'], whitelist)
    dotfiles = {}
    try:
        with open(os.path.expanduser(whitelist_path)) as fd:
            text = fd.read()
            dotfiles = json.loads(text)  # create dictionary from json file
    except:
        print('You aren\'t monitoring any files. (╯°□°）╯︵ ┻━┻')
    else:
        for key, value in dotfiles.items():
            print("{} --> {}".format(key, value))

def main():
    """Entry point of the program"""
    #
    # Read config files
    #
    load_config()  

    #
    # Validate config values
    #
    validate_config_settings()

    #
    # Parse command line arguments.
    #
    parser = argparse.ArgumentParser(description='Manage your dotfiles')
    subparsers = parser.add_subparsers(title='subcommands',
                                       description='valid subcommands',
                                       help='additional help')
    subparsers.required = True  # require one command
    subparsers.dest = 'command'  # require one command

    list_parser = subparsers.add_parser('list', help='list managed files')
    add_parser = subparsers.add_parser('add', help='add a file to be tracked')
    add_parser.add_argument('dotfile')

    opts = parser.parse_args()

    #
    # Based on what arguments were given, call the appropriate function.
    #
    cmd_table = {'add': add_command, 'list': list_command,
             }
    cmd_table[opts.command](opts)

if __name__ == '__main__':
    main()
