# dfm
Dotfile Manager

The easy way to keep track of and sync your dotfiles to github.

## Installation Instructions
Installation is easy, simply copy `dfm` to a location that is executable (for
instance, /usr/local/bin or ~/bin).

## FAQ
When I first install and run dfm I get `Error while processing configuration
value. folder : ~/dotfiles/`

* dfm defaults to ~/dotfiles as your dotfiles folder. dfm will not create the
  dotfile folder for you, this is something that you must do yourself. You can
  change dfm configuration values by creating a configuration file (in
  /etc/dfm.conf or ~/.dfm.conf), but you will still need to make sure that the
  folder directory exists.
