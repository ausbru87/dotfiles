#!/bin/bash
# DevOps/Infrastructure profile aliases
# kubectl, helm, terraform, openshift

###############################################################################
# Kubernetes (kubectl)
###############################################################################

alias k='kubectl'
alias kg='kubectl get'
alias kga='kubectl get all'
alias kgp='kubectl get pods'
alias kgs='kubectl get services'
alias kgd='kubectl get deployments'
alias kgn='kubectl get nodes'
alias kgns='kubectl get namespaces'
alias kgi='kubectl get ingress'
alias kgcm='kubectl get configmaps'
alias kgsec='kubectl get secrets'

# Wide output
alias kgpw='kubectl get pods -o wide'
alias kgnw='kubectl get nodes -o wide'

# All namespaces
alias kgaa='kubectl get all --all-namespaces'
alias kgpaa='kubectl get pods --all-namespaces'

# Describe
alias kd='kubectl describe'
alias kdp='kubectl describe pod'
alias kds='kubectl describe service'
alias kdd='kubectl describe deployment'
alias kdn='kubectl describe node'

# Delete
alias kdel='kubectl delete'
alias kdelp='kubectl delete pod'

# Apply/Create
alias ka='kubectl apply -f'
alias kcr='kubectl create'

# Logs
alias kl='kubectl logs'
alias klf='kubectl logs -f'

# Exec
alias kx='kubectl exec -it'
alias kpf='kubectl port-forward'

# Context/Namespace
alias kctx='kubectl config current-context'
alias kcon='kubectl config get-contexts'
alias kusecon='kubectl config use-context'
alias kns='kubectl config view --minify --output "jsonpath={..namespace}"'
alias ksetns='kubectl config set-context --current --namespace'

# Rollout
alias kro='kubectl rollout'
alias kros='kubectl rollout status'
alias kror='kubectl rollout restart'

# Events
alias kev='kubectl get events --sort-by=.metadata.creationTimestamp'

###############################################################################
# OpenShift (oc)
###############################################################################

if command -v oc &>/dev/null; then
  alias o='oc'
  alias og='oc get'
  alias oga='oc get all'
  alias ogp='oc get pods'
  alias ogs='oc get services'
  alias ogd='oc get deployments'
  alias ogdc='oc get dc'
  alias ogr='oc get routes'
  alias ogbc='oc get bc'
  alias ogis='oc get is'
  alias ogproj='oc get projects'

  alias od='oc describe'
  alias odel='oc delete'
  alias oa='oc apply -f'

  alias ol='oc logs'
  alias olf='oc logs -f'
  alias orsh='oc rsh'

  alias oproj='oc project'
  alias onewproj='oc new-project'

  alias ostart='oc start-build'
  alias oro='oc rollout'
  alias odeploy='oc rollout latest'

  alias ost='oc status'
  alias owhoami='oc whoami'
  alias owhot='oc whoami -t'
  alias ologin='oc login'
fi

###############################################################################
# Helm
###############################################################################

if command -v helm &>/dev/null; then
  alias h='helm'
  alias hl='helm list'
  alias hla='helm list --all-namespaces'
  alias hi='helm install'
  alias hu='helm upgrade'
  alias hd='helm delete'
  alias hs='helm search'
  alias hr='helm repo'
  alias hru='helm repo update'
fi

###############################################################################
# Terraform
###############################################################################

if command -v terraform &>/dev/null; then
  alias tf='terraform'
  alias tfi='terraform init'
  alias tfp='terraform plan'
  alias tfa='terraform apply'
  alias tfd='terraform destroy'
  alias tfo='terraform output'
  alias tfs='terraform state'
  alias tfsl='terraform state list'
  alias tfv='terraform validate'
  alias tff='terraform fmt'
fi

###############################################################################
# Helper Functions
###############################################################################

# Get logs from all containers in a pod
klogs() {
  [[ -z "$1" ]] && { echo "Usage: klogs <pod-name> [namespace]"; return 1; }
  kubectl logs -n "${2:-default}" "$1" --all-containers=true
}

# Exec into pod
kexec() {
  [[ -z "$1" ]] && { echo "Usage: kexec <pod-name> [command] [namespace]"; return 1; }
  kubectl exec -it -n "${3:-default}" "$1" -- "${2:-/bin/bash}"
}

# Get secret value (base64 decoded)
kgetsec() {
  [[ -z "$2" ]] && { echo "Usage: kgetsec <secret-name> <key>"; return 1; }
  kubectl get secret "$1" -o jsonpath="{.data.$2}" | base64 --decode
}

# Restart deployment
krestart() {
  [[ -z "$1" ]] && { echo "Usage: krestart <deployment-name>"; return 1; }
  kubectl rollout restart deployment "$1"
}

# List container images in use
kimages() {
  kubectl get pods --all-namespaces -o jsonpath="{.items[*].spec.containers[*].image}" | tr -s '[[:space:]]' '\n' | sort -u
}

# Pods not running
kpodnr() {
  kubectl get pods --all-namespaces --field-selector=status.phase!=Running
}
