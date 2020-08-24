FROM alpine

# Ignore to update version here, it is controlled by .travis.yml and build.sh
# docker build --no-cache --build-arg KUBECTL_VERSION=${tag} --build-arg HELM_VERSION=${helm} -t ${image}:${tag} .
ARG HELM_VERSION=3.3.0
ARG KUBECTL_VERSION=1.18.8

# https://docs.aws.amazon.com/eks/latest/userguide/install-aws-iam-authenticator.html
ARG AWS_IAM_AUTH_VERSION_URL

# Install helm (latest release)
# ENV BASE_URL="https://storage.googleapis.com/kubernetes-helm"
ENV BASE_URL="https://get.helm.sh"
ENV TAR_FILE="helm-v${HELM_VERSION}-linux-amd64.tar.gz"
RUN apk add --update --no-cache curl ca-certificates bash git && \
    curl -L ${BASE_URL}/${TAR_FILE} |tar xvz && \
    mv linux-amd64/helm /usr/bin/helm && \
    chmod +x /usr/bin/helm && \
    rm -rf linux-amd64 && \
    apk del curl && \
    rm -f /var/cache/apk/*

# add helm-diff
RUN helm plugin install https://github.com/databus23/helm-diff

# Install kubectl (same version of aws esk)
RUN apk add --update --no-cache curl && \
    curl -LO https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl && \
    mv kubectl /usr/bin/kubectl && \
    chmod +x /usr/bin/kubectl

# Install aws-iam-authenticator (latest version)
RUN curl -L ${AWS_IAM_AUTH_VERSION_URL} -o aws-iam-authenticator && \
    mv aws-iam-authenticator /usr/bin/aws-iam-authenticator && \
    chmod +x /usr/bin/aws-iam-authenticator

# Install eksctl (latest version)
RUN curl --silent --location "https://github.com/weaveworks/eksctl/releases/download/latest_release/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp && \
    mv /tmp/eksctl /usr/bin && \
    chmod +x /usr/bin/eksctl

# Install awscli, curl, jq
RUN apk add --update --no-cache python3 curl jq && \
    python3 -m ensurepip && \
    pip3 install --upgrade pip && \
    pip3 install awscli

RUN kubectl version --client && eksctl version && helm version && aws-iam-authenticator --version
WORKDIR /apps
