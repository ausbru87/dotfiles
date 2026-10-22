#!/bin/bash
# Infrastructure-as-code profile aliases
# terraform, ansible

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
# Ansible
###############################################################################

if command -v ansible &>/dev/null; then
  alias ap='ansible-playbook'
  alias apc='ansible-playbook --check --diff'
  alias ainv='ansible-inventory --graph'
  alias al='ansible-lint'
fi
