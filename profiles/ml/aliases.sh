#!/bin/bash
# ML/AI profile aliases
# Conda, pip, Jupyter, PyTorch, TensorFlow

###############################################################################
# Conda
###############################################################################

# Initialize conda (common locations)
if [[ -f "$HOME/miniconda3/etc/profile.d/conda.sh" ]]; then
  source "$HOME/miniconda3/etc/profile.d/conda.sh"
elif [[ -f "$HOME/anaconda3/etc/profile.d/conda.sh" ]]; then
  source "$HOME/anaconda3/etc/profile.d/conda.sh"
elif [[ -f "/opt/conda/etc/profile.d/conda.sh" ]]; then
  source "/opt/conda/etc/profile.d/conda.sh"
fi

alias ca='conda activate'
alias cda='conda deactivate'
alias cel='conda env list'
alias cec='conda env create'
alias cer='conda env remove'
alias ci='conda install'
alias cu='conda update'
alias cua='conda update --all'
alias cl='conda list'
alias cs='conda search'

###############################################################################
# Pip
###############################################################################

alias pip='pip3'
alias pipi='pip install'
alias pipu='pip install --upgrade'
alias pipun='pip uninstall'
alias pipl='pip list'
alias pipf='pip freeze'
alias pipfr='pip freeze > requirements.txt'
alias pipir='pip install -r requirements.txt'

###############################################################################
# Jupyter
###############################################################################

alias jn='jupyter notebook'
alias jl='jupyter lab'
alias jc='jupyter console'
alias jkl='jupyter kernelspec list'

###############################################################################
# Python
###############################################################################

alias py='python3'
alias python='python3'
alias ipy='ipython'
alias pym='python -m'
alias pytest='python -m pytest'
alias pytestv='python -m pytest -v'
alias pytestcov='python -m pytest --cov'

###############################################################################
# Virtual Environments
###############################################################################

alias venv='python -m venv'
alias venvc='python -m venv .venv'
alias venva='source .venv/bin/activate'

# Create and activate venv
mkvenv() {
  python -m venv "${1:-.venv}" && source "${1:-.venv}/bin/activate"
}

###############################################################################
# Poetry (if installed)
###############################################################################

if command -v poetry &>/dev/null; then
  alias poi='poetry install'
  alias poa='poetry add'
  alias por='poetry run'
  alias pos='poetry shell'
  alias pob='poetry build'
  alias pop='poetry publish'
fi

###############################################################################
# GPU Utilities
###############################################################################

# NVIDIA GPU monitoring
if command -v nvidia-smi &>/dev/null; then
  alias nv='nvidia-smi'
  alias nvw='watch -n 1 nvidia-smi'
  alias nvt='nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader'

  # GPU memory usage
  gpumem() {
    nvidia-smi --query-gpu=memory.used,memory.total --format=csv
  }
fi

###############################################################################
# Helper Functions
###############################################################################

# Quick conda env create from yaml
condaenv() {
  [[ -z "$1" ]] && { echo "Usage: condaenv <env-name> [python-version]"; return 1; }
  conda create -n "$1" python="${2:-3.10}" -y && conda activate "$1"
}

# Export conda env
condaexport() {
  conda env export > environment.yml
  echo "Exported to environment.yml"
}

# Check PyTorch GPU
torchgpu() {
  python -c "import torch; print(f'CUDA available: {torch.cuda.is_available()}'); print(f'Device count: {torch.cuda.device_count()}') if torch.cuda.is_available() else None"
}

# Check TensorFlow GPU
tfgpu() {
  python -c "import tensorflow as tf; print(f'GPUs: {tf.config.list_physical_devices(\"GPU\")}')"
}

# Run Jupyter with specific port
jnp() {
  jupyter notebook --port="${1:-8888}"
}

# Training run with timestamp
trainrun() {
  local script="${1:-train.py}"
  local logdir="${2:-logs}"
  local timestamp=$(date +%Y%m%d_%H%M%S)
  mkdir -p "$logdir"
  python "$script" 2>&1 | tee "$logdir/train_$timestamp.log"
}
