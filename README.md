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
behind a few simple commands and make everything highly configurable and
extensible through a yaml config file.

That's all nice in theory, but we still need it to have some initial
functionality to prove the concept. Below are the subcommands we have out of the
box.

#### New file templating
Your current editor might have some limited facility for this.
However, I don't want this functionality to be dependent on my editor
configuration and being able to tranfer that nicely to a new machine.
Instead I'd rather depend on flat, versioned, text file templates.

```shell
m template create bash bob
m tcb bob
m t c zet "how-to-eat-fish"
```

Data driven through the MyCLI configuration file (config.yaml).

#### Local search

```shell
m search "search term"
m search --options "-i" "search term"
m search --group "code" "search term"
```

### Install

First, make sure you're using the version of ruby that you want to install Thor
in and use to run MyCLI. Then run the commands below. The install script is
interactive.

```shell
gem install thor
git clone https://github.com/grymoire7/MyCLI.git
cd MyCLI && ruby install.rb
```

### Experiment

When first created, the generated MyCLI `config.yaml` points to templates and
other input files in `./examples` writes output to files in `./examples/output`.
So you can begin playing right away.

The following templating examples use this bit of `config.yml` configuration:

```yaml
commands:
  templates:
    create:
      sprint:
        filepath: "$MYCLI_EXAMPLES/org/sprint.erb"
        target:
          path: "$MYCLI_EXAMPLES/output"
          suffix: ".org"
        namespace_data: *sprint_data
        namespace_subkey: 'default'
      zet:
        filepath: "$MYCLI_EXAMPLES/org/zet.erb"
        target:
          path: "$MYCLI_EXAMPLES/output"
          suffix: ".org"
          prefix: "<%%= today %>-"
          permissions: '0644'   # settable on erb files only
      bash:
        filepath: "$MYCLI_EXAMPLES/bin/example_script.sh"
        target:
          path: "$MYCLI_EXAMPLES/output"
      python:
        filepath: "$MYCLI_EXAMPLES/bin/example_script.py"
        target:
          path: "$MYCLI_EXAMPLES/output"
          suffix: ".py"
```

#### New file templating examples: bash

Create a new bash script named `bob` by copying an example script to a
target location based on the configuration above.

```shell
m template create bash bob
m t c b boc # <- same
m tcb bob   # <- same if using experimental feature
```

#### New file templating examples: zet

Create a new Zettelkasten org file from an ERB template, prefixed with
the current date and suffixed with `.org`.

```shell
m template create zet "how-to-eat-fish"
m t c z "how-to-eat-fish" # <- same
m tcz "how-to-eat-fish"   # <- same if using experimental feature
```

#### New file templating examples: sprint

Create a new sprint notes file from an ERB template, suffixed with `.org`.

```shell
m template create --subkey '2022-07-07' sprint "current"
m t c --subkey '2022-07-07' sprint "current" # <- same
```

Of course, you can modify or extend the `config.yaml` to suit your own
file templating needs.

#### Local file search examples

The following local search examples use this bit of `config.yml` configuration:

```yaml
  search:
    executable: rg
    arguments: "-i -n --color always"
    paths:
      scripts:
        - "$MYCLI_EXAMPLES/bin"
      org:
        - "$MYCLI_EXAMPLES/org"
      mydocs:
        - "$MYCLI_EXAMPLES/Documents"
      projects:
        apple: &apple
          code:
            - "$MYCLI_EXAMPLES/projects/apple/app"
            - "$MYCLI_EXAMPLES/projects/apple/lib"
          docs:
            - "$MYCLI_EXAMPLES/projects/apple/README.md"
            - "$MYCLI_EXAMPLES/projects/apple/docs"
        orange: &orange
         code:
           - "$MYCLI_EXAMPLES/projects/orange/app"
           - "$MYCLI_EXAMPLES/projects/orange/lib"
         docs:
           - "$MYCLI_EXAMPLES/projects/orange/README.md"
           - "$MYCLI_EXAMPLES/projects/orange/docs"
      fruit:
        - *apple
        - *orange
```

#### Local file search example: sprint

Create a new sprint notes file from an ERB template, suffixed with `.org`.
With the `-g|--group` option you can narrow the search to all paths in
subtrees matching the key provided to the option.

```shell
m search puts      # search all defined paths for `puts`
m s -g code puts   # search paths in subtrees labelled `code`
m s -o "-A 2 -n"-g scripts echo # specify options for `rg`
```

### Configure

After exprimenting with the intial `config.yaml`, you may want to start
customizing your `config.yaml` file to suit your own workflow.

### Contribute
See `CONTRIBUTING.md`.

