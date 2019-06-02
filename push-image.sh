#!/bin/sh
set -e

docker login -u "$DOCKER_USER" -p "$DOCKER_PASS"

_image_tag=$1
_docker_repo=${2:-kenfdev/multiarch-nuxt}

# If the tag starts with v, treat this as a official release
if echo "$_image_tag" | grep -q "^v"; then
  # strip the 'v' from tag
	_app_version=$(echo "${_image_tag}" | cut -d "v" -f 2)
else
	_app_version=$_image_tag
fi


export DOCKER_CLI_EXPERIMENTAL=enabled

echo "pushing ${_docker_repo}:${_app_version}"

docker_push_all () {
	repo=$1
	tag=$2

	# Push each image individually
	docker push "${repo}:${tag}"
	docker push "${repo}-linux-arm32v7:${tag}"
	# docker push "${repo}-linux-arm64v8:${tag}"

	# Create and push a multi-arch manifest
	docker manifest create "${repo}:${tag}" \
		"${repo}:${tag}" \
  	"${repo}-linux-arm32v7:${tag}"
		# "${repo}-linux-arm64v8:${tag}"

	docker manifest push "${repo}:${tag}"
}

docker_push_all "${_docker_repo}" "${_app_version}"

if echo "$_image_tag" | grep -q "^v"; then
	echo "pushing ${_docker_repo}:latest"
	docker_push_all "${_docker_repo}" "latest"
elif echo "$_image_tag" | grep -q "master"; then
	docker_push_all "${_docker_repo}" "master"
	docker push "kenfdev/multiarch-nuxt-dev:${_app_version}"
fi