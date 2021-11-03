## Usage

```
set -o allexport
source .env
set +o allexport
```

```
export KUBECONFIG=~/.kube/config
bin/k8s_apply.py
```
