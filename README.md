# MyCLI

## Description
MyCLI is a highly-configurable, data-driven command line tool designed for
brevity and versatility.

### An origin story
If you've used the command line for a long time you eventually accumulate a
collection of scripts, functions, and aliases which are intended to make your
life easier. At first, this works well but eventually you end up with a bunch of
scripts and functions that are groups of similar--but not quite the
same--functionality, all with different names. Also, you collect aliases to try
to make the things you do a lot as short as possible. Finally, you discover that
the space of available short names is very limited and code if very scattered.

MyCLI aims to hide a bunch of functionality behind a single letter (m) in a
highly configurable and extensible way. It does this in Ruby, using the Thor
library to define tasks, with configuration through a `config.yaml` file.

To get things started, MyCLI provides a few versatile tasks out of the box.

### New file templating
With `m templates create` you can create new files from templates with a lot of
flexibility and very few keystrokes (`m t c`). New files can be created either
by copying existing examples to a new place/name or by specifying an ERB
template. When using templates, you can specify template data several ways in
your `config.yaml` file. You can specify the data directly, by URL (TODO), or be
prompted for it at generation time. You can even supply a multiple sets of data
that is indexed/keyed however you like (e.g. by deploy date) and then specify
that key at generation time. All of which can be flexibly defined in your
`config.yaml` file which easily versioned and transferable to new systems.

After install, your new `config.yaml` file will point to example templates in
`./examples` and write new files to `./examples/output`. You'll be all set to
start playing with the examples and/or start making your own. See
"Experimenting" below.

### Local search
Another frequent task is search. This MyCLI task (`m s`) does not try to
recreate or replace your current text search tool (e.g `rg`, `ag`, `grep`,
etc.). Instead it focuses on wrangling the groups of files and directories
that you might frequently want to search.

TODO: It also allows you to specify different or additional search arguments per
search group.

After install, your new `config.yaml` file will point to example files and paths
in `./examples`. You'll be all set to start playing with the examples and/or
start defining your own search groups and options. See "Experimenting" below.

## Install

First, make sure you're using the version of ruby that you want to install Thor
in and use to run MyCLI. Then run the commands below. The install script is
interactive.

```shell
gem install thor
git clone https://github.com/grymoire7/MyCLI.git
cd MyCLI && ruby install.rb
```

## Experiment

When first created, the generated MyCLI `config.yaml` points to templates and
other input files in `./examples` writes output to files in `./examples/output`.
So you can begin playing right away.

### Templates

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

### Search

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

#### Local file search example

With the `-g|--group` option you can narrow the search to all paths in
subtrees matching the key provided to the option.

```shell
m search "search term"
m search --group "code" "search term"
m search puts      # search all defined paths for `puts`
m s -g code puts   # search paths in subtrees labelled `code`
m search --options "-i" "search term"
m s -o "-A 2 -n"-g scripts echo # specify options for `rg`
```

## Configure

After exprimenting with the intial `config.yaml`, you may want to start
customizing your `config.yaml` file to suit your own workflow.

## Contribute
See `CONTRIBUTING.md`.

