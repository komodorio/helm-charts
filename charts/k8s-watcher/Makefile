deploy:
	 helm repo update
	 helm upgrade --install k8s-watcher komodorio/k8s-watcher --debug \
	 --set apiKey=${KOMOKW_API_KEY} \
	 --set watcher.collectHistory=true \
	 --set watcher.nameBlacklist="{leader,election}" \
	 --set watcher.resources.secret=true

deploy-with-kiali:
	 helm repo update
	 helm upgrade --install k8s-watcher komodorio/k8s-watcher --debug \
	 --set apiKey=${KOMOKW_API_KEY} \
	 --set kialiApiKey=${KOMOKW_KIALI_API_KEY} \
	 --set watcher.collectHistory=true \
	 --set watcher.nameBlacklist="{leader,election}" \
	 --set watcher.sources.kiali.url="http://kiali.istio-system.svc.cluster.local:20001" \
	 --set watcher.sources.kiali.username="admin" \
	 --set watcher.sources.kiali.password="admin" \
	 --set watcher.resources.secret=true

generate-kube:
	helm template k8s-watcher . -f values.yaml \
	--set watcher.collectHistory=true \
	--set watcher.nameBlacklist="{leader,election}" \
	--set apiKey="YOUR_APIKEY_AS_BASE_64" \
	> generated.yaml
	cat generated.yaml | ./helm-fan-out.sh kube-install
	rm generated.yaml
	sed -i "s/WU9VUl9BUElLRVlfQVNfQkFTRV82NA==/YOUR_APIKEY_AS_BASE_64/g" kube-install/k8s-watcher/templates/secret-credentials.yaml
