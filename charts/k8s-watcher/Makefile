deploy:
   helm repo update
	 helm upgrade --install k8s-watcher komodorio/k8s-watcher --debug \
	 --set apiKey=${KOMOKW_API_KEY} \
	 --set watcher.collectHistory=true \
	 --set watcher.nameBlacklist="{leader,election}"

deploy-with-kiali:
	deploy:
   helm repo update
	 helm upgrade --install k8s-watcher komodorio/k8s-watcher --debug \
	 --set apiKey=${KOMOKW_API_KEY} \
	 --set watcher.collectHistory=true \
	 --set watcher.nameBlacklist="{leader,election}" \
	 --set watcher.sources.kiali.url="http://kiali.istio-system.svc.cluster.local:20001" \
	 --set watcher.sources.kiali.username="admin" \
	 --set watcher.sources.kiali.password="admin" \

generate-kube:
	helm template k8s-watcher . -f values.yaml \
	--set watcher.collectHistory=true \
	--set watcher.nameBlacklist="{leader,election}" \
	--set apiKey="YOUR_API_KEY_HERE" \
	> generated.yaml
	cat generated.yaml | ./helm-fan-out.sh kube-install
	rm generated.yaml