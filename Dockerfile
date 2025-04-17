FROM alpine:3.19

RUN apk add --no-cache bash jq curl \
    && curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -

COPY scan.sh /scan.sh

ENTRYPOINT ["/scan.sh"]