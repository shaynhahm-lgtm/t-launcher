#!/data/data/com.termux/files/usr/bin/bash
# t-launcher installer.  Usage: bash install.sh   |   bash install.sh --uninstall
RAW="https://raw.githubusercontent.com/shaynhahm-lgtm/t-launcher/${T_BRANCH:-main}"
TOOLS="t-launcher pkgkey fkey topen fmget"
if [ "${1:-}" = "--uninstall" ]; then
  for t in $TOOLS; do rm -f "$PREFIX/bin/$t"; done
  echo "Removed: $TOOLS"; exit 0
fi
command -v fzf >/dev/null || pkg install -y fzf
command -v file >/dev/null || pkg install -y libmagic >/dev/null 2>&1 || pkg install -y file >/dev/null 2>&1 || true
SRC="$(dirname "$(readlink -f "${BASH_SOURCE[0]:-$0}")")"
for t in $TOOLS; do
  if [ -f "$SRC/install.sh" ] && [ -f "$SRC/$t" ]; then cp "$SRC/$t" "$PREFIX/bin/$t"
  else curl -fsSL "$RAW/$t" -o "$PREFIX/bin/$t" || { echo "Download failed: $t"; exit 1; }
  fi
  chmod +x "$PREFIX/bin/$t"
done
# Older setups run t-launcher through a shell alias to a copy like ~/bin/termux-launcher.sh.
# Update that copy too (backed up first) so the alias doesn't keep running the old version.
for rc in "$HOME/.zshrc" "$HOME/.bashrc"; do
  OLD="$(grep -o 'alias t-launcher=.*' "$rc" 2>/dev/null | grep -o '[^ "'"'"']*launcher[^ "'"'"']*\.sh' | head -1)"
  OLD="${OLD/#\~/$HOME}"; OLD="${OLD/\$HOME/$HOME}"
  if [ -n "$OLD" ] && [ -f "$OLD" ]; then
    mkdir -p "$HOME/.toolkit-backup"
    cp "$OLD" "$HOME/.toolkit-backup/old-launcher-$(date +%Y%m%d-%H%M%S).sh"
    cp "$PREFIX/bin/t-launcher" "$OLD" && chmod +x "$OLD" && echo "Also updated $OLD (your t-launcher alias points there)"
  fi
done
echo -e "\033[1;32mInstalled!\033[0m  Type: t-launcher   (also: topen <file>, fmget)"
