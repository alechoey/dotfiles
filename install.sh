#! /usr/local/bin/bash

pushd `dirname $0` > /dev/null
SCRIPT_PATH=`pwd`
popd > /dev/null

HOMEBREW_PACKAGES=(
  'git'
  'vim'
  'tmux'
  'reattach-to-user-namespace'
  'zsh'
)

declare -A VIM_PACKAGE_REMOTES
VIM_PACKAGE_REMOTES=(
  [vim-colors-solarized]='git@github.com:altercation/vim-colors-solarized.git'
  [supertab]='git@github.com:ervandew/supertab.git'
  [ctrlp.vim]='git@github.com:kien/ctrlp.vim.git'
  [nerdtree]='git@github.com:scrooloose/nerdtree.git'
  [vim-fugitive]='git@github.com:tpope/vim-fugitive.git'
  [vim-unimpaired]='git@github.com:tpope/vim-unimpaired.git'
  [vim-airline]='git@github.com:vim-airline/vim-airline.git'
  [vim-airline-themes]='git@github.com:vim-airline/vim-airline-themes.git'
)

install_brew_package() {
  pkg_name=$1
  if brew ls --versions $pkg_name > /dev/null;
  then
    echo "$pkg_name already installed; skipping"
  else
    if $DRY_RUN;
    then
      echo "Would have installed $pkg_name, but --dry-run was enabled"
    else
      brew install $pkg_name
    fi
  fi
}

install_vim_package() {
  package_name=$1
  git_remote=${VIM_PACKAGE_REMOTES[$package_name]}

  exec 3>&2
  exec 2> /dev/null
  ls -H "$HOME/.vim/bundle/$package_name" > /dev/null
  if [[ $? != 0 ]];
  then
    git clone --quiet $git_remote "$HOME/.vim/bundle/$package_name"
  else
    echo "$git_remote was already installed"
  fi
  exec 2>&3
}

link_and_backup_dotfile() {
  filename=$1
  pathname="$HOME/$filename"

  exec 3>&2
  exec 2> /dev/null
  ls -H $pathname > /dev/null
  if [[ $? != 0 ]];
  then
    if $DRY_RUN;
    then
      echo "Would have linked $filename to $pathname  but --dry-run was enabled"
    else
      link_dotfile $filename
    fi
  else
    backup_pathname="$pathname.bak"
    if $DRY_RUN;
    then
      echo "Would have moved $pathname to $backup_pathname and linked $filename to $pathname but --dry-run was enabled"
    else
      backup_dotfile $filename
      link_dotfile $filename
    fi
  fi
  exec 2>&3
}

backup_dotfile() {
  filename=$1
  pathname="$HOME/$filename"
  backup_pathname="$pathname.bak"
  mv $pathname $backup_pathname
}

link_dotfile() {
  filename=$1
  ln -s "$SCRIPT_PATH/$filename"
}


DRY_RUN=false
OPTS=`getopt -o d: --long dry-run -n 'install.sh' --"$@"`

case $1 in
  -d|--dry-run)
    DRY_RUN=true; shift;;
  *)
    ;;
esac

which -s brew
if [[ $? != 0 ]];
then
  if $DRY_RUN;
  then
    echo 'Would have installed brew, but --dry-run was enabled'
  else
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  fi
else
  echo 'brew already installed; skipping'
fi

# Install all homebrew packages
for pkg in "${HOMEBREW_PACKAGES[@]}"
do
  install_brew_package $pkg
done

# Link all dotfiles
mkdir -p "$HOME/.vim/bundle"

# Install all vim packages
for package_name in  "${!VIM_PACKAGE_REMOTES[@]}"
do
  install_vim_package $package_name
done

# Backup and link all the dotfiles
link_and_backup_dotfile '.bash'
link_and_backup_dotfile '.gitconfig'
link_and_backup_dotfile '.gitk'
link_and_backup_dotfile '.tmux.conf'
link_and_backup_dotfile '.vim'
link_and_backup_dotfile '.vimrc'
link_and_backup_dotfile '.zshrc'