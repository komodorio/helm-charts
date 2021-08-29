#/bin/sh

apk add curl bash make yq
curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash
mv kustomize /usr/local/bin
make generate-kube
v=$(yq e '.appVersion' charts/k8s-watcher/Chart.yaml)
cd manifests/base
kustomize edit set image komodorio/k8s-watcher=komodorio/k8s-watcher:$v
kustomize edit set label app.kubernetes.io/watcher-version:$v