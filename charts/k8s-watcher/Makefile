deploy:
	 helm repo update
	 helm upgrade --install k8s-watcher komodorio/k8s-watcher --debug \
	 --set apiKey=${KOMOKW_API_KEY} \
	 --set watcher.collectHistory=true \
	 --set watcher.nameBlacklist="{leader,election}" \
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

# for MacOS
docker-generate-kube:
	docker run -v $(PWD):/app --workdir /app --entrypoint sh  -it alpine/helm "-c" "apk add bash make && make generate-kube"