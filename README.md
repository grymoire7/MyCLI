# MyCLI

## Description
MyCLI is a highly-configurable, data-driven command line tool designed for
brevity and versitility.

### An origin story
If you've used the command line for a long time you eventually accumulate a
collection of scripts, functions, and aliases which are intended to make
your life easier. At first, this works well and life is good. Eventually,
however, you end up with a bunch of scripts and functions that are groups of
similar, but not quite the same, functionality. Also, you collect aliases to try
to make the things you do a lot as short as possible. And you discover that the
space of available short names is very limited.

To mitigate the problem we can write more general scripts and move aliases into
application specific config (like using `g` for `git` and moving aliases into
`.gitconfig`. For example, `g lg`, `g co`, etc.). This helps but it only goes
so far.

This problem was the impetus for this project, to a hide bunch of functionality
behind a few simple commands and make everything highly configuralbe and
extensible through a yaml config file.

That's all nice in theory, but we still need it to have some initial
functionality to prove the concept. Below are the subcommands we have out of the
box.

#### New file templating
Honestly, your current favorite editor might have some facility for this.
However, I don't want this functionality to be dependent on my editor
configuration and being able to tranfer that nicely to a new machine.
Instead I'd rather depend on flat, versioned, text file templates.

```shell
m t bash
m t zet "how-to-eat-fish"
```

Data driven through the MyCLI configuration file (config.yaml).

#### Local search

```shell
m search "search term"
m search --options "-i" "search term"
m search --group "code" "search term"
```

#### Aliases

```shell
m alias [alias]
# Config file snippet
# --------------------
#   aliases:
#     zet: "m template create zet"
#     s: "m template create sprint -k"
#     c: "cal -A 1 -B 1"
alias ma='m alias'
ma zet how-to-juggle # m t c zet
ma s '2022-07-07'   # m t c sprint -k 2022-07-07
ma c
```

### Install (WIP)

First, make sure you're using the version of ruby that you want to install thor
in and use to run MyCLI. Then run the commands below. The install script is
interactive.

```shell
gem install thor
git clone https://github.com/grymoire7/MyCLI.git
cd MyCLI && ruby install.rb
```

#### Manual install

```shell
MYCLI_DIR=$HOME/projects
cd $MYCLI_DIR
git clone https://github.com/grymoire7/MyCLI.git
cp $MYCLI_DIR/MyCLI/m.sh ~/bin/m
cp $MYCLI_DIR/example.config.yaml $MYCLI_DIR/config.yaml
# edit m to use correct ruby version and repo path
# install thor
gem install thor
# test
m help  # or just m
```

### Configure

```shell
# edit $MYCLI_DIR/config.yaml
# define template and search paths
```

### Usage


### Contribute
See `CONTRIBUTING.md`.

