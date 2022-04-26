deploy:
	 helm repo update
	 helm upgrade --install k8s-watcher komodorio/k8s-watcher --debug \
	 --set apiKey=${KOMOKW_API_KEY} \
	 --set watcher.collectHistory=true \
	 --set watcher.nameDenylist="{leader,election}" \
	 --set watcher.resources.secret=false \
	 --set watcher.enableAgentTaskExecution=true \
	 --set watcher.allowReadingPodLogs=true

generate-kube:
	helm template k8s-watcher ./charts/k8s-watcher -f ./charts/k8s-watcher/values.yaml \
	--set watcher.collectHistory=true \
	--set watcher.nameDenylist="{leader,election}" \
	--set watcher.nameDenylist="{leader,election}" \
	--set watcher.resources.secret=false \
	--set watcher.enableAgentTaskExecution=true \
	--set watcher.allowReadingPodLogs=true \
	--set apiKey="YOUR_APIKEY_AS_BASE_64" \
	> generated.yaml
	cat generated.yaml | ./charts/k8s-watcher/helm-fan-out.sh charts/k8s-watcher/kube-install
	rm generated.yaml
	sed -i "s/WU9VUl9BUElLRVlfQVNfQkFTRV82NA==/YOUR_APIKEY_AS_BASE_64/g" charts/k8s-watcher/kube-install/k8s-watcher/templates/secret-credentials.yaml

docker-generate-kube:
	docker run -v $(PWD):/app --workdir /app --entrypoint sh  -it alpine/helm "-c" "/app/docker-generate-kube.sh"
