#!/data/data/com.termux/files/usr/bin/bash
# t-launcher installer.  Usage: bash install.sh   |   bash install.sh --uninstall
RAW="https://raw.githubusercontent.com/shaynhahm-lgtm/t-launcher/main"
TOOLS="t-launcher pkgkey fkey"
if [ "${1:-}" = "--uninstall" ]; then
  for t in $TOOLS; do rm -f "$PREFIX/bin/$t"; done
  echo "Removed: $TOOLS"; exit 0
fi
command -v fzf >/dev/null || pkg install -y fzf
SRC="$(dirname "$(readlink -f "${BASH_SOURCE[0]:-$0}")")"
for t in $TOOLS; do
  if [ -f "$SRC/install.sh" ] && [ -f "$SRC/$t" ]; then cp "$SRC/$t" "$PREFIX/bin/$t"
  else curl -fsSL "$RAW/$t" -o "$PREFIX/bin/$t" || { echo "Download failed: $t"; exit 1; }
  fi
  chmod +x "$PREFIX/bin/$t"
done
echo -e "\033[1;32mInstalled!\033[0m  Type: t-launcher"
