# altKYMSU
altKYMSU is a fork from **KYMSU** (Keep Your macOs Stuff Updated)
https://github.com/welcoMattic/kymsu

Each plugin notifie you about available update and upgrade apps and packages.

homebrew and pecl plugins notifie you if apache/php configuration files have been modified.



## Plug-ins:

- **atom** (plug-ins)
- **antibody** (zsh plug-ins)
- **homebrew**  (brew and cask)
- **installed** (create a list of all your brew, pip, npm... stuffs and a Brewfile). 
- **npm** (javascript package) (local or global packages) (can update nvm script)
- **mas** (Mac Appstore)
- **pip** (Python Package index) (pip or pip3)
- **PECL** (PHP modules)
- **Wordpress** (wp-cli) <u>(for testing only)</u>

 

## Requirements

- [Homebrew](https://brew.sh/)
- [jq](https://github.com/stedolan/jq) *(brew install jq)* for processing JSON data (homebrew plugin)

Optionnal:

- [pipdeptree](https://pypi.python.org/pypi/pipdeptree) *(pip install pipdeptree)* for checking dependancies (pip plugin)
- [terminal-notifier](https://github.com/julienXX/terminal-notifier) *(brew install terminal-notifier)* for sending macOS notification (all plugins)
- ~~[Bash 5](https://www.gnu.org/software/bash/) *(brew install bash)* for associative array (homebrew plugin)~~ (homebrew plugin 2.0)



## Installation

`$ git clone git@github.com:Bruno21/kymsu.git && cd kymsu2 && ./install.sh`

A symbolic link is created in `/usr/local/bin/`

Plug-ins are placed in `~/.kymsu/`



## Usage

Only update all the things:  `$ kymsu2` 

With cleanup after updates: `$ kymsu2 --cleanup`

No distract mode  (no user interaction):`$ kymsu2 --nodistract`

Prefix plugin with a _ to ignore it:

```bash
# _wp.sh is disabled (still beta)
~/.kymsu/plugins.d $ ls
00-kymsu.sh _wp.sh      atom.sh     homebrew.sh mas.sh      npm.sh      pecl.sh     pip.sh
```

`Installed.sh` create a Markdown file with all yours installed stuffs and a Brewfile. I suggest to disable the plugin and run it manually.



## Settings

 There is a <u>settings section</u> on top of each plug-in:

- *[homebrew-pip]* don't update a module, package...: add it to the `do_not_update` array on the top.

```bash
$ nano homebrew.sh
declare -a do_not_update=('virtualbox,virtualbox-extension-pack')
```

- *[homebrew]* display info on updated pakages: `display_info=true`
- *[homebrew-npm-pecl-pip]* no distract mode  (no user interaction): `no_distract=false`
  *If running Homebrew plug-in in no_distract mode, Casks with 'latest' version number won't be updated.*
- *[npm]* run npm maintenance tools: `doctor=true`
- *[pip]* `version=pip or pip3`  `user="" or "--user"`



## Update

Git pull and re-run install.sh:

`$ cd kymsu2 && git pull && ./install.sh`



## Automate

altKYMSU comes with 2 **.plist** files (one for kymsu2, one for installed.sh) to automate the use of KYMSU.  Please edit and drag them into the folder ~ / Library / LaunchAgents

For configure LaunchAgent, I suggest [LaunchControl](http://www.soma-zone.com).



## Uninstall

Run uninstall.sh:

`$ cd kymsu2 && ./uninstall.sh`



## Credit

All credit goes to [welcoMattic](https://github.com/welcoMattic/kymsu)



## License

Same as KYMSU (MIT)

