alias k=kubectl
alias watch='watch '
source <(kubectl completion bash)
source <(oc completion bash)
source <(helm completion bash)
# source /etc/bash_completion
complete -F __start_kubectl k
bind 'set bell-style none'
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"