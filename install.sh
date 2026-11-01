#!/data/data/com.termux/files/usr/bin/bash
# t-launcher installer.
#   bash install.sh                      core tools
#   bash install.sh --addons             core tools + every add-on
#   bash install.sh --addons netkey ...  core tools + just those add-ons
#   bash install.sh --uninstall          remove everything
RAW="https://raw.githubusercontent.com/shaynhahm-lgtm/t-launcher/${T_BRANCH:-main}"
TOOLS="t-launcher pkgkey fkey topen fmget"
ADDONS="dropwatch cardkey netkey offset tdoctor clipkey talk sukey cleankey recentkey"   # these live in ~/bin
if [ "${1:-}" = "--uninstall" ]; then
  [ -f "$PREFIX/bin/t-launcher" ] && bash "$PREFIX/bin/t-launcher" --share off >/dev/null 2>&1   # only removes our own share hook
  for t in $TOOLS; do rm -f "$PREFIX/bin/$t"; done
  [ -x "$HOME/bin/dropwatch" ] && "$HOME/bin/dropwatch" uninstall >/dev/null 2>&1
  [ -x "$HOME/bin/clipkey" ] && "$HOME/bin/clipkey" uninstall >/dev/null 2>&1
  [ -x "$HOME/bin/sukey" ] && "$HOME/bin/sukey" uninstall >/dev/null 2>&1
  for a in $ADDONS; do rm -f "$HOME/bin/$a"; done
  echo "Removed: $TOOLS $ADDONS"
  [ -d "$HOME/.local/share/cleankey/trash" ] && echo "cleankey's trash was kept (your files): ~/.local/share/cleankey/trash and /sdcard/.cleankey-trash"
  exit 0
fi
WANT=""
if [ "${1:-}" = "--addons" ]; then shift; WANT="${*:-$ADDONS}"; fi
command -v fzf >/dev/null || pkg install -y fzf
command -v file >/dev/null || pkg install -y libmagic >/dev/null 2>&1 || pkg install -y file >/dev/null 2>&1 || true
SRC="$(dirname "$(readlink -f "${BASH_SOURCE[0]:-$0}")")"
for t in $TOOLS; do
  if [ -f "$SRC/install.sh" ] && [ -f "$SRC/$t" ]; then cp "$SRC/$t" "$PREFIX/bin/$t"
  else curl -fsSL "$RAW/$t" -o "$PREFIX/bin/$t" || { echo "Download failed: $t"; exit 1; }
  fi
  chmod +x "$PREFIX/bin/$t"
done
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
  chmod +x "$HOME/bin/$a"; GOT="$GOT $a"
done
if [ -n "$GOT" ]; then
  case ":$PATH:" in
    *":$HOME/bin:"*) ;;
    *) for rc in "$HOME/.zshrc" "$HOME/.bashrc"; do
         [ -f "$rc" ] && ! grep -q '# t-launcher path' "$rc" && printf '\nexport PATH="$HOME/bin:$PATH"  # t-launcher path\n' >>"$rc"
       done
       export PATH="$HOME/bin:$PATH" ;;
  esac
  case " $GOT " in *" dropwatch "*) "$HOME/bin/dropwatch" install ;; esac
  case " $GOT " in *" clipkey "*) "$HOME/bin/clipkey" setup ;; esac
fi
# Older setups run t-launcher through a shell alias to a copy like ~/bin/termux-launcher.sh.
#  - copy still there: update it too (backed up first) so the alias doesn't run an old version
#  - copy gone: the alias is broken ("No such file"), so turn that alias line off (rc backed up
#    first); plain `t-launcher` then runs the installed copy in $PREFIX/bin
FIXED_ALIAS=""
for rc in "$HOME/.zshrc" "$HOME/.bashrc"; do
  [ -f "$rc" ] || continue
  BACKED=""
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
[ -n "$FIXED_ALIAS" ] && echo "This Termux window still remembers the old alias: open a new session, or run  unalias t-launcher"
exit 0
