# Tool manifests

Things Homebrew does not track. Regenerate before a machine change.

## Restore

```sh
brew bundle install --file=~/.config/Brewfile

# Go tools. GOBIN is set to /opt/homebrew/bin on this setup, so `go install`
# lands there rather than ~/go/bin - set it before running this, or the
# binaries end up somewhere your PATH may not cover.
go env -w GOBIN=/opt/homebrew/bin
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

## Gotchas

- `golangci-lint` is NOT a brew formula here, it is a `go install` binary. Neovim's
  nvim-lint shells out to `golangci-lint version` when its module loads, so a missing
  binary makes the whole lint `config` block fail, not just linting.
- One internal tool is not listed, because this repo is public: build it from its clone
  under ~/Stockbit/lib with `go install ./cmd/...`.
- `jsonlint` and `yamllint` are referenced by the Neovim lint config but were never
  installed. nvim-lint skips a missing linter silently, so this is harmless.

## Regenerate

See the commands in the session that created these, or simply re-run each
tool's list command and redirect into the matching file.
