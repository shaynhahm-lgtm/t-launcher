#!/data/data/com.termux/files/usr/bin/bash
# t-launcher installer.
#   bash install.sh                      core tools
#   bash install.sh --addons             core tools + every add-on
#   bash install.sh --addons netkey ...  core tools + just those add-ons
#   bash install.sh --uninstall          remove everything this installer put there
RAW="https://raw.githubusercontent.com/shaynhahm-lgtm/t-launcher/${T_BRANCH:-main}"
TOOLS="t-launcher pkgkey fkey topen fmget"
ADDONS="dropwatch cardkey netkey offset tdoctor clipkey talk sukey cleankey recentkey"   # these live in ~/bin
# addons/INDEX describes the add-ons. It is data: we only ever pull plain names out of it.
DATA="${XDG_DATA_HOME:-$HOME/.local/share}/t-launcher"
BUILTIN="$ADDONS"   # names this installer itself vouches for
# The manifest: one line per file t-launcher installed, "sha256<TAB>path". Uninstall goes by it,
# and a file you changed since it was installed is yours now: it is left alone.
MANIFEST="$DATA/manifest"
sum_of() { sha256sum -- "$1" 2>/dev/null | cut -c1-64; }
recorded() { [ -f "$MANIFEST" ] && awk -F'\t' -v p="$1" '$2 == p { s = $1 } END { if (s != "") print s }' "$MANIFEST"; }
record() { # record PATH  (no sha256sum = no record; the older rules below then apply to that file)
  local s; s="$(sum_of "$1")"; [ -n "$s" ] || return 0
  mkdir -p "$DATA" || return 0
  { [ -f "$MANIFEST" ] && awk -F'\t' -v p="$1" '$2 != p' "$MANIFEST"; printf '%s\t%s\n' "$s" "$1"; } >"$MANIFEST.tmp.$$" \
    && mv -f "$MANIFEST.tmp.$$" "$MANIFEST"
}
unchanged() { local r; r="$(recorded "$1")"; [ -n "$r" ] && [ "$r" = "$(sum_of "$1")" ]; }   # 0 only if recorded AND still the same
index_names() { # adds any add-on the index lists that the built-in list above doesn't
  local n
  [ -f "$DATA/INDEX" ] || return 0
  for n in $(head -c 65536 "$DATA/INDEX" | sed -n 's/^name:[[:space:]]*\([a-z0-9][a-z0-9-]*\)[[:space:]]*$/\1/p'); do
    case " $ADDONS " in *" $n "*) ;; *) ADDONS="$ADDONS $n" ;; esac
  done
}
# Files from before the manifest existed have no record. For those: a name that is ONLY in the
# index (not in the built-in list) could be wrong, stale, or the same as one of your own scripts,
# so uninstall deletes it only if it is a plain file (not a link) that says "t-launcher add-on"
# in its first 5 lines. Anything else is left alone.
is_ours() {
  [ -f "$1" ] && [ ! -L "$1" ] && head -c 4096 "$1" 2>/dev/null | head -n 5 | grep -qaiF 't-launcher add-on'
}
index_names
if [ "${1:-}" = "--uninstall" ]; then
  [ -f "$PREFIX/bin/t-launcher" ] && bash "$PREFIX/bin/t-launcher" --share off >/dev/null 2>&1   # only removes our own share hook
  TGONE=""; CHANGED=""
  for t in $TOOLS; do   # recorded and changed since install = yours now, kept. No record (before 9.3) = removed, as before
    f="$PREFIX/bin/$t"
    [ -e "$f" ] || [ -L "$f" ] || continue
    if [ -n "$(recorded "$f")" ] && ! unchanged "$f"; then CHANGED="$CHANGED $t"; else rm -f "$f"; TGONE="$TGONE $t"; fi
  done
  [ -x "$HOME/bin/dropwatch" ] && "$HOME/bin/dropwatch" uninstall >/dev/null 2>&1
  [ -x "$HOME/bin/clipkey" ] && "$HOME/bin/clipkey" uninstall >/dev/null 2>&1
  [ -x "$HOME/bin/sukey" ] && "$HOME/bin/sukey" uninstall >/dev/null 2>&1
  # Every add-on name we know of: the lists above plus anything the manifest recorded in ~/bin
  if [ -f "$MANIFEST" ]; then
    for a in $(awk -F'\t' -v d="$HOME/bin/" 'index($2, d) == 1 { print substr($2, length(d) + 1) }' "$MANIFEST" | grep -x '[A-Za-z0-9][A-Za-z0-9._-]*'); do
      case " $ADDONS " in *" $a "*) ;; *) ADDONS="$ADDONS $a" ;; esac
    done
  fi
  GONE=""; KEPT=""
  for a in $ADDONS; do
    f="$HOME/bin/$a"
    [ -e "$f" ] || [ -L "$f" ] || continue
    if [ -n "$(recorded "$f")" ]; then            # we installed it: remove only if it is still what we installed
      if [ -f "$f" ] && [ ! -L "$f" ] && unchanged "$f"; then rm -f "$f"; GONE="$GONE $a"; else CHANGED="$CHANGED $a"; fi
      continue
    fi
    case " $BUILTIN " in                          # no record (installed before 9.3): the older rules
      *" $a "*) rm -f "$f"; GONE="$GONE $a" ;;
      *) if is_ours "$f"; then rm -f "$f"; GONE="$GONE $a"; else KEPT="$KEPT $a"; fi ;;
    esac
  done
  rm -f "$DATA/INDEX" "$DATA/INDEX.dev" "$MANIFEST"
  echo "Removed:$TGONE$GONE"
  [ -n "$CHANGED" ] && echo "Left alone (changed since t-launcher installed it, so it's yours now):$CHANGED"
  [ -n "$KEPT" ] && echo "Left alone in ~/bin (not clearly a t-launcher add-on, so not deleted):$KEPT"
  [ -d "$HOME/.local/share/cleankey/trash" ] && echo "cleankey's trash was kept (your files): ~/.local/share/cleankey/trash and /sdcard/.cleankey-trash"
  exit 0
fi
SRC="$(dirname "$(readlink -f "${BASH_SOURCE[0]:-$0}")")"
# The add-on index first, so the list below is current. No index is fine: built-in list is used.
mkdir -p "$DATA"
if [ -f "$SRC/install.sh" ] && [ -f "$SRC/addons/INDEX" ]; then cp "$SRC/addons/INDEX" "$DATA/INDEX"
elif curl -fsSL "$RAW/addons/INDEX" -o "$DATA/INDEX.part"; then mv -f "$DATA/INDEX.part" "$DATA/INDEX"
else rm -f "$DATA/INDEX.part"; echo "Couldn't get the add-on index (add-ons still work, with shorter descriptions)."
fi
index_names
WANT=""
if [ "${1:-}" = "--addons" ]; then shift; WANT="${*:-$ADDONS}"; fi
# t-launcher can't run without fzf, so it gets installed. Say so first, in plain words.
if ! command -v fzf >/dev/null; then
  echo "t-launcher needs one package that isn't on this phone yet: fzf (the search menu it is built on)."
  echo "Installing it now with:  pkg install fzf"
  pkg install -y fzf || echo "fzf didn't install. t-launcher won't start until it does. Try:  pkg install fzf"
fi
if ! command -v file >/dev/null; then
  echo "Also installing the small 'file' tool, which tells t-launcher what kind of file something is."
  pkg install -y libmagic >/dev/null 2>&1 || pkg install -y file >/dev/null 2>&1 || echo "'file' didn't install. t-launcher still works, with less detail about unknown files."
fi
# T_KEEP_MODIFIED=1 (dev mode's update): a tool that isn't exactly what was installed is not replaced.
KEEP="${T_KEEP_MODIFIED:-0}"; KEPT_TOOLS=""
for t in $TOOLS; do
  if [ "$KEEP" = 1 ] && [ -e "$PREFIX/bin/$t" ] && ! unchanged "$PREFIX/bin/$t"; then
    KEPT_TOOLS="$KEPT_TOOLS $t"; continue
  fi
  if [ -f "$SRC/install.sh" ] && [ -f "$SRC/$t" ]; then cp "$SRC/$t" "$PREFIX/bin/$t"
  else curl -fsSL "$RAW/$t" -o "$PREFIX/bin/$t.part" && mv -f "$PREFIX/bin/$t.part" "$PREFIX/bin/$t" \
    || { rm -f "$PREFIX/bin/$t.part"; echo "Download failed: $t"; exit 1; }
  fi
  chmod +x "$PREFIX/bin/$t"; record "$PREFIX/bin/$t"
done
[ -n "$KEPT_TOOLS" ] && echo "Dev mode: kept your own copy of:$KEPT_TOOLS  (changed since install, or installed before 9.3)"
# Share → Termux → Edit opens files in t-launcher's inbox (skipped if you already have a termux-file-editor)
bash "$PREFIX/bin/t-launcher" --share auto
# Add-ons go in ~/bin, next to your own tools
GOT=""
for a in $WANT; do
  case " $ADDONS " in *" $a "*) ;; *) echo "Unknown add-on: $a (choices: $ADDONS)"; continue ;; esac
  mkdir -p "$HOME/bin"
  if [ -f "$SRC/install.sh" ] && [ -f "$SRC/addons/$a" ]; then cp "$SRC/addons/$a" "$HOME/bin/$a"
  else curl -fsSL "$RAW/addons/$a" -o "$HOME/bin/$a" || { echo "Download failed: $a"; continue; }
  fi
  chmod +x "$HOME/bin/$a"; record "$HOME/bin/$a"; GOT="$GOT $a"
done
if [ -n "$GOT" ]; then
  case ":$PATH:" in
    *":$HOME/bin:"*) ;;
    *) for rc in "$HOME/.zshrc" "$HOME/.bashrc"; do
         [ -f "$rc" ] && ! grep -q '# t-launcher path' "$rc" && printf '\nexport PATH="$HOME/bin:$PATH"  # t-launcher path\n' >>"$rc"
       done
       export PATH="$HOME/bin:$PATH" ;;
  esac
fi
# Older setups run t-launcher through a shell alias to a copy like ~/bin/termux-launcher.sh.
#  - copy still there: update it too (backed up first) so the alias doesn't run an old version
#  - copy gone: the alias is broken ("No such file"), so turn that alias line off (rc backed up
#    first); plain `t-launcher` then runs the installed copy in $PREFIX/bin
FIXED_ALIAS=""
for rc in "$HOME/.zshrc" "$HOME/.bashrc"; do
  [ -f "$rc" ] || continue
  BACKED=""
  [ "$KEEP" = 1 ] && break   # dev mode: your alias and the copy it points to are left alone
  while IFS=: read -r n line; do
    OLD="$(printf '%s' "$line" | grep -o '[^ "'"'"']*launcher[^ "'"'"']*\.sh' | head -1)"
    [ -n "$OLD" ] || continue
    OLD="${OLD/#\~/$HOME}"; OLD="${OLD/\$HOME/$HOME}"
    mkdir -p "$HOME/.toolkit-backup"
    if [ -f "$OLD" ]; then
      cp "$OLD" "$HOME/.toolkit-backup/old-launcher-$(date +%Y%m%d-%H%M%S).sh"
      cp "$PREFIX/bin/t-launcher" "$OLD" && chmod +x "$OLD" && echo "Also updated $OLD (your t-launcher alias points there)"
    else
      RCNAME="${rc##*/}"
      [ -n "$BACKED" ] || { cp "$rc" "$HOME/.toolkit-backup/${RCNAME#.}-$(date +%Y%m%d-%H%M%S)"; BACKED=1; }
      sed -i "${n}s|^|# |; ${n}s|\$|   # turned off by t-launcher installer: file was missing|" "$rc"
      echo "Fixed: your t-launcher alias in ~/$RCNAME pointed to ~${OLD#"$HOME"}, which is gone. Turned it off (backup in ~/.toolkit-backup)."
      FIXED_ALIAS=1
    fi
  done < <(grep -n '^[[:space:]]*alias t-launcher=' "$rc")
done
echo -e "\033[1;32mInstalled!\033[0m  Type: t-launcher   (Ctrl+S = split screen · also: topen <file>, fmget)"
[ -n "$GOT" ] && echo -e "Add-ons:$GOT   (more in t-launcher → MENU → Add-ons)"
[ "$(bash "$PREFIX/bin/t-launcher" --share status 2>/dev/null)" = on ] && echo "Share to t-launcher is on: in any app, Share → Termux → Edit"
case " $GOT " in *" sukey "*) echo "sukey needs a one-time Shizuku pairing: run  sukey setup" ;; esac
# Installing never starts a background job. These two can run one, when you choose to:
case " $GOT " in *" dropwatch "*) echo "dropwatch isn't watching yet. To start it:  dropwatch install" ;; esac
case " $GOT " in *" clipkey "*) echo "clipkey isn't saving clips yet. To start it:  clipkey setup" ;; esac
[ -n "$FIXED_ALIAS" ] && echo "This Termux window still remembers the old alias: open a new session, or run  unalias t-launcher"
exit 0
