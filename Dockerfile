FROM alpine:3.19.1 as oc-builder

ADD https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable/openshift-client-src.tar.gz /

RUN apk add --no-cache \
        alpine-sdk \
        go \
        linux-headers \
        krb5-dev

RUN mkdir /source && \
    tar xfz \
        /openshift-client-src.tar.gz \
        -C /source \
        --strip-components 1 

WORKDIR /source

RUN make oc
RUN (set -x; cd "$(mktemp -d)" && \
  OS="$(uname | tr '[:upper:]' '[:lower:]')" && \
  ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" && \
  KREW="krew-${OS}_${ARCH}" && \
  curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" && \
  tar zxvf "${KREW}.tar.gz" && \
  ./"${KREW}" install krew \
)
WORKDIR /
RUN apk add kubectl git
ENV PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
WORKDIR /root/.krew/bin
# ENV KREW_PLUGINS="access-matrix allctx cert-manager creyaml \
#     ctx deprecations df-pv eksporter exec-cronjob grep konfig ns rabbitmq split-yaml starboard \
#     support-bundle tree unused-volumes  view-cert view-serviceaccount-kubeconfig  \
#     view-secret  who-can whoami rolesum  resource-versions \
#     outdated node-shell neat get-all mc ipick minio" 
ENV KREW_PLUGINS="cert-manager ctx deprecations df-pv exec-cronjob grep konfig ns rabbitmq split-yaml \
 support-bundle tree unused-volumes  view-cert view-serviceaccount-kubeconfig  \
    view-secret  who-can whoami resource-versions \
    outdated node-shell neat get-all mc ipick minio" 
RUN    for plugin in $KREW_PLUGINS; do ./kubectl-krew install $plugin; done
RUN wget https://releases.hashicorp.com/terraform/0.12.21/terraform_0.12.21_linux_amd64.zip
RUN unzip terraform_0.12.21_linux_amd64.zip && rm terraform_0.12.21_linux_amd64.zip
RUN mv terraform /root/terraform



FROM alpine:3.19.1

COPY --from=oc-builder /source/oc /usr/local/bin
# COPY --from=oc-builder /root/helm/bin /usr/local/bin
COPY --from=oc-builder /root/.krew /root/.krew
COPY --from=oc-builder /root/terraform /usr/local/bin
COPY --from=oc-builder /usr/local/bin/kubectl* /usr/local/bin
COPY helm /usr/local/bin
RUN apk add --no-cache aws-cli

RUN apk add bash curl
RUN apk add bash-completion
RUN apk add git kubectl
COPY .bashrc /root/
RUN terraform -install-autocomplete
WORKDIR /root
CMD bash