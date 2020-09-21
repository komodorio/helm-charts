deploy:
	 cd k8s-watcher && helm upgrade --install k8s-watcher . -f values.yaml --debug \
	 --set watcher.listExisting=true \
	 --set watcher.nameBlacklist="{leader,election}" \
	 #--set watcher.sources.kiali.url="http://kiali.istio-system.svc.cluster.local:20001" \
	 #--set watcher.sources.kiali.username="admin" \
	 #--set watcher.sources.kiali.password="admin" \

generate-kube:
	helm template k8s-watcher . -f values.yaml \
	--set watcher.listExisting=true \
	--set watcher.nameBlacklist="{leader,election}" \
	--set watcher.secret.installationId="YOUR_INSTALLATION_ID_HERE" \
	> generated.yaml
	cat generated.yaml | ./helm-fan-out.sh kube-install
	rm generated.yaml