# Suffix aliases: bare `path/to/file.ext` opens in $EDITOR.
# zsh expands `foo.ts` to `$EDITOR foo.ts` when no command precedes it.
# Interactive only: tools that source .zshrc for non-interactive runs (e.g.
# machine_setup's `$HOME/install_*.sh`) would otherwise open the script in nvim.
[[ -o interactive ]] || return

# code
alias -s {ts,tsx,js,jsx,mjs,cjs}=$EDITOR
alias -s {lua,rs,go,py,rb}=$EDITOR
alias -s {sh,zsh,bash}=$EDITOR
alias -s {svelte,vue,astro}=$EDITOR
alias -s {sql,gd,gdshader,vim}=$EDITOR

# markup / config
alias -s {json,jsonc,yaml,yml,toml}=$EDITOR
alias -s {md,mdx,txt,log}=$EDITOR
alias -s {html,htm,css,scss,sass}=$EDITOR
alias -s {conf,cfg,ini,env}=$EDITOR
