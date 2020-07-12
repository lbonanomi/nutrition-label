FROM alpine:3.10

RUN apk update \
 && apk add jq curl gettext

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
