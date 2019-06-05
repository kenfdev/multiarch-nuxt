#!/bin/sh

_image_tag=$1
_docker_repo=${2:-kenfdev/multiarch-nuxt}

# If the tag starts with v, treat this as a official release
if echo "$_image_tag" | grep -q "^v"; then
	_app_version=$(echo "${_image_tag}" | cut -d "v" -f 2)
else
	_app_version=$_image_tag
fi

echo "Building ${_docker_repo}:${_app_version}"

export DOCKER_CLI_EXPERIMENTAL=enabled

# Build multiarch-nuxt image for a specific arch
docker_build () {
	base_image=$1
	tag=$2

  docker build \
		--build-arg BASE_IMAGE=${base_image} \
		--tag "${tag}" \
		--no-cache=true .
}

# Tag docker images of all architectures
docker_tag_all () {
	repo=$1
	tag=$2
	docker tag "${_docker_repo}:${_app_version}" "${repo}:${tag}"
	docker tag "${_docker_repo}-linux-arm32v7:${_app_version}" "${repo}-linux-arm32v7:${tag}"
	# docker tag "${_docker_repo}-linux-arm64v8:${_app_version}" "${repo}-linux-arm64v8:${tag}"
}

docker_build "node:10-alpine" "${_docker_repo}:${_app_version}"
docker_build "arm32v7/node:12" "${_docker_repo}-linux-arm32v7:${_app_version}"
# docker_build "arm64v8/node:12" "${_docker_repo}-linux-arm64v8:${_app_version}"

# Tag as 'latest' for official release; otherwise tag as kenfdev/multiarch-nuxt:master
if echo "$_image_tag" | grep -q "^v"; then
	docker_tag_all "${_docker_repo}" "latest"
else
	docker_tag_all "${_docker_repo}" "master"
	docker tag "${_docker_repo}:${_app_version}" "kenfdev/multiarch-nuxt-dev:${_app_version}"
fi