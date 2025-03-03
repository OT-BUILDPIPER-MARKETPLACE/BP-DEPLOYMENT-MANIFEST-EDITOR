FROM alpine:latest
RUN apk add --no-cache --upgrade bash
RUN apk add jq yq git

COPY build.sh .
COPY getDynamicVars.sh .
RUN chmod +x build.sh getDynamicVars.sh

ADD BP-BASE-SHELL-STEPS /opt/buildpiper/shell-functions/

ENV NEW_SERVICE_ACCOUNT ""

ENV SLEEP_DURATION 5s
ENV ACTIVITY_SUB_TASK_CODE BP-DEPLOYMENT-MANIFEST-EDITOR
ENV VALIDATION_FAILURE_ACTION WARNING

ENTRYPOINT [ "./build.sh" ]
