# Backups, swaps and undos are stored here.
mkdir -p $DOTFILES/caches/vim

# Install vim plugins
# UTF-8 locale: the vimrc uses non-ASCII listchars; </dev/null: no keypress prompts
LANG=C.UTF-8 LC_ALL=C.UTF-8 vim +PlugInstall +qall </dev/null

# Compile YouCompleteMe
# if [ ! -e ~/.vim/plugged/YouCompleteMe/python/ycm/youcompleteme.pyc ]; then
#   pushd ~/.vim/plugged/YouCompleteMe
#   ./install.py --clang-completer
#   popd
# fi
