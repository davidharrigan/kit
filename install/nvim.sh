#/usr/bin/env bash
set -e

PLUG_DIR="$HOME/.local/share/nvim/site/autoload/plug.vim"

echo "> installing nvim dependencies..."

# Install plug
if [ ! -f $PLUG_DIR ]; then
echo "> installing vim plug...."
echo ""

curl -fLo $PLUG_DIR --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi

echo ""
echo "done ✅"
