# Path to your oh-my-zsh configuration.
ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
ZSH_THEME="shizzard"

# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# Set to this to use case-sensitive completion
# CASE_SENSITIVE="true"

# Comment this out to disable bi-weekly auto-update checks
# DISABLE_AUTO_UPDATE="true"

# Uncomment to change how many often would you like to wait before auto-updates occur? (in days)
# export UPDATE_ZSH_DAYS=13

# Uncomment following line if you want to disable colors in ls
# DISABLE_LS_COLORS="true"

# Uncomment following line if you want to disable autosetting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment following line if you want red dots to be displayed while waiting for completion
# COMPLETION_WAITING_DOTS="true"

# Uncomment following line if you want to disable marking untracked files under
# VCS as dirty. This makes repository status check for large repositories much,
# much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

for dir in \
  ~/bin \
  /opt/local/bin \
  /opt/local/sbin \
; do 
  if [[ -d $dir ]]; then path+=$dir; fi 
done;
export PATH;

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
plugins=(osx git git-extras sublime encode64 redis-cli sprunge urltools tmux)

source $ZSH/oh-my-zsh.sh

# Customize to your needs...
export LC_ALL="en_US.utf-8"
export PYTHONPATH=/opt/local/Library/Frameworks/Python.framework/Versions/2.7/lib/python2.7/site-packages

alias erl-r15b03='. /Users/shizz/bin/erlang/erl-r15b03/activate'
alias erl-17.5='. /Users/shizz/bin/erlang/erl-17.5/activate'



devel() {
	git checkout develop;
	git submodule foreach git checkout develop;
	git pull;
	git submodule foreach git pull;
}

rel() {
	if [ -z "$1" ]; then
		echo "Specify release version";
		exit 1;
	fi;

	git checkout releases/$1;
	git submodule foreach git checkout releases/$1;
	git pull;
	git submodule foreach git pull;
}

newbranch() {
	if [ -z "$1" ]; then
		echo "Specify task number";
		exit 1;
	fi;
	if [ -z "$2" ]; then
		echo "Specify short task definition (no spaces)";
		exit 1;
	fi;

	git checkout -b "df-xmppcs-$1-$2"
}
