#!/usr/bin/env bash

# Prerequisite
# Make sure you set secret enviroment variables in Travis CI
# DOCKER_USERNAME
# DOCKER_PASSWORD
# API_TOKEN

set -ex

build() {

  # helm latest
  helm=$(curl -s https://github.com/helm/helm/releases)
  helm=$(echo $helm\" |grep -oP '(?<=tag\/v)[0-9][^"]*'|grep -v \-|sort -Vr|head -1)
  echo $helm

  # aws-iam-authenticator latest
  iam_auth=$(curl https://github.com/kubernetes-sigs/aws-iam-authenticator/releases/latest | sed -r 's/.*http.*v(.*)">.*/\1/')
  iam_auth_url="https://github.com/kubernetes-sigs/aws-iam-authenticator/releases/download/v${iam_auth}/aws-iam-authenticator_${iam_auth}_linux_amd64"
  echo ${iam_auth_url}

  echo "Found new version, building the image ${image}:${tag}"
  docker build  --cache-from $CI_REGISTRY_IMAGE:latest \
         --build-arg KUBECTL_VERSION=${tag} \
         --build-arg HELM_VERSION=${helm} \
         --build-arg AWS_IAM_AUTH_VERSION_URL="${iam_auth_url}" \
         --tag ${image}:${tag} --tag $CI_REGISTRY_IMAGE:latest .

  # run test
  version=$(docker run -ti --rm ${image}:${tag} helm version --client)
  echo $version
  # Client: &version.Version{SemVer:"v2.9.0-rc2", GitCommit:"08db2d0181f4ce394513c32ba1aee7ffc6bc3326", GitTreeState:"clean"}
  if [[ "${version}" == *"Error: unknown flag: --client"* ]]; then
    echo "Detected Helm3+"
    version=$(docker run -ti --rm ${image}:${tag} helm version)
    #version.BuildInfo{Version:"v3.0.0-beta.2", GitCommit:"26c7338408f8db593f93cd7c963ad56f67f662d4", GitTreeState:"clean", GoVersion:"go1.12.9"}
  fi
  version=$(echo ${version}| awk -F \" '{print $2}')
  if [ "${version}" == "v${helm}" ]; then
    echo "matched"
  else
    echo "unmatched"
    exit
  fi
}

#login first
docker login -u gitlab-ci-token -p $CI_BUILD_TOKEN registry.gitlab.com

# build and push image then
docker pull $CI_REGISTRY_IMAGE:latest || true

#build
build

#push
docker push $CI_REGISTRY_IMAGE:${tag}
docker push $CI_REGISTRY_IMAGE:latest
