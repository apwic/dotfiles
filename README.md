# `Dotfiles`

This `dotfiles` is using git bare repository from this [reference](https://stegosaurusdormant.com/bare-git-repo/).

## Setup this `dotfiles`

1. Create the bare repository.

```sh
git init --bare $HOME/dotfiles
```

1. Setup alias for the `git-dir` and `work-dir`.

```sh
echo "alias dotfiles='git --git-dir=$HOME/dotfiles/ --work-tree=$HOME'" >> $HOME/.zshrc
```

Now you can use `dotfiles` as a `git` command.

1. Not to display all the untracked file in the `$HOME` directory.

```sh
dotfiles status.showUntrackedFiles no

```

1. Set up your `dotfiles` repository as the origin.

```sh
dotfiles remote add https://github.com/apwic/dotfiles.git
```

### Use this `dotfiles`

1. Clone this repository as a non-bare repository and keep the snapshot at the `dotfiles-tmp`.
```sh
 git clone \
   --separate-git-dir=$HOME/dotfiles \
   https://github.com/apwic/dotfiles.git \
   dotfiles-tmp
```

1. Setup alias for the `git-dir` and `work-dir`.

```sh
echo "alias dotfiles='git --git-dir=$HOME/dotfiles/ --work-tree=$HOME'" >> $HOME/.zshrc
```

1. Not to display all the untracked file in the `$HOME` directory.

```sh
dotfiles status.showUntrackedFiles no

```

1. Copy the snapshot from the `dotfiles-tmp` to the `$HOME` directory.
```sh
rsync --recursive --verbose --exclude '.git' dotfiles-tmp/ $HOME/
```

1. Remove the `dotfiles-tmp` as the `config` will already in the right place.
```sh
 rm -rf dotfiles-tmp
```

1. Setup the submodule to `init` and `update` from the origin.
```sh
dotfiles submodule init
dotfiles submodule update
```
