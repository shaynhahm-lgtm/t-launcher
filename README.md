# t-launcher

**A color-coded file browser and command finder for Termux.**
Browse your files, see what anything is, and open it with the right thing, all from one fuzzy-search menu.
Comes with **topen** (open any file with the right tool), **fmget** (install the top 10 Termux file managers), **pkgkey** (what can my installed packages do?) and **fkey** (what is this file and how do I use it?).

<img src="screenshots/1.jpg" width="260"> <img src="screenshots/2.jpg" width="260"> <img src="screenshots/3.jpg" width="260"> 

## Install

```
curl -fsSL https://raw.githubusercontent.com/shaynhahm-lgtm/t-launcher/main/install.sh | bash
```

Then type `t-launcher`. Needs only `fzf`, which the installer adds for you.

## What it does

- **Enter just opens it**: t-launcher figures out what the file really is and opens it with the right thing. Scripts run, archives extract, photos/video/PDFs/APKs open in the right Android app, text opens in a viewer, configs open in nano. **Tab** (or Ctrl+O) brings up the full action menu instead.
- **Color-coded listing**: folders, scripts, executables, archives, packages, web pages, and text files each get their own color. Folders are listed first.
- **Live preview**: see inside a file or folder before opening it (Ctrl+P toggles it).
- **Smart actions**: select a file and the best action is starred at the top: run a `.py`, extract a `.tar.gz`, open an `.html` in your browser. `chmod +x` is handled for you.
- **fkey built in**: "Commands for this file" lists the right commands for that file type with your filename already filled in. Pick one, tweak it, run it.
- **pkgkey built in**: search every installed package, preview the commands it gives you, then run, read help, or open the man page.
- **Install any script as a command**: turn a script into something you can type from anywhere.
- **No dead ends**: Esc goes back one step like a browser, and `..` always goes up.
- **10 file managers, one tap**: open the current folder in yazi, mc, ranger, nnn, lf, vifm, broot, clifm, fff or walk. Not installed yet? Pick it and it installs itself.
- **Handy shortcuts**: jump to Downloads or home, toggle hidden files.

## The tools on their own

```
pkgkey               list installed packages
pkgkey <package>     show its commands, then run / help / man them
pkgkey -s <term>     search packages
pkgkey -c <command>  which package a command came from
pkgkey -o            export everything to a Markdown file

fkey <ext|file>      what a file type is and how to work with it
fkey -l              list all known file types

topen <file>         open any file with the right thing
topen -n <file>      dry run: what is it, and what would open it
topen -l             what opens what
topen -e             add your own rules, e.g.  md = glow -p {}

fmget                menu of the top 10 file managers (Tab marks several)
fmget all            install all 10
fmget yazi lf        install just those
fmget --extras       yazi preview helpers (images, video, PDF, fd, ripgrep, zoxide)
fmget -l             what's installed
```

### How topen decides

1. Your own rules in `~/.config/topen/rules` win.
2. Then the file extension (`.py`, `.tar.gz`, `.apk`, `.mp4`...).
3. No extension or an unknown one? It looks inside: the `#!` line (and fixes Linux paths like `/bin/bash` that don't exist on Termux), the file's magic bytes (ELF, zip, gzip, PDF, PNG...), then `file`, then text vs binary.

Anything a file needs that isn't installed (python, unzip, 7z, java...) gets installed for you. Programs sitting on shared storage, where Android won't run them, are run from a temp copy.

## Uninstall

```
curl -fsSL https://raw.githubusercontent.com/shaynhahm-lgtm/t-launcher/main/install.sh | bash -s -- --uninstall
```

## License

MIT
