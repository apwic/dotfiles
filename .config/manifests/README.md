# Tool manifests

Things Homebrew does not track. Regenerate before a machine change.

## Restore

```sh
brew bundle install --file=~/.config/Brewfile

# Go tools
xargs -n1 go install < ~/.config/manifests/go-tools.txt

# uv tools (names only; strip the version column)
awk '{print $1}' ~/.config/manifests/uv-tools.txt | xargs -n1 uv tool install

# npm globals (skip npm itself)
grep -v '^npm$' ~/.config/manifests/npm-global.txt | xargs -n1 npm i -g

# cargo
xargs -n1 cargo install < ~/.config/manifests/cargo-tools.txt

# node
nvm install $(grep -m1 '^v' ~/.config/manifests/node-versions.txt)

# VS Code extensions
xargs -n1 code --install-extension < ~/.config/manifests/vscode-extensions.txt
```

## Regenerate

See the commands in the session that created these, or simply re-run each
tool's list command and redirect into the matching file.
