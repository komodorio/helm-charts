FROM nginx:1.31.8-alpine3.24-slim
# Set to rebuild the same nginx version with fresh Alpine packages. Remove on the next nginx bump.
ARG REVISION=patch1

RUN apk upgrade --no-cache && apk add --no-cache openssl
