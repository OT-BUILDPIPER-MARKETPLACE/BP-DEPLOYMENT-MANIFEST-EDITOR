FROM alpine:latest

# Create buildpiper user and group
RUN addgroup -g 65522 buildpiper && \
    adduser -u 65522 -G buildpiper -D -h /home/buildpiper buildpiper && \
    mkdir -p /home/buildpiper && \
    chown -R buildpiper:buildpiper /home/buildpiper

# Create required directories and set ownership
RUN mkdir -p \
    /src/reports \
    /bp/data \
    /bp/execution_dir \
    /opt/buildpiper/shell-functions \
    /opt/buildpiper/data \
    /bp/workspace \
    /usr/local/bin \
    /var/lib/apt/lists \
    /etc/timezone \
    /opt/python_versions \
    /opt/jdk \
    /opt/maven && \
    chown -R buildpiper:buildpiper /src /bp /opt /usr /tmp

# Install required packages
RUN apk add --no-cache --upgrade bash jq yq git gettext libintl coreutils diffutils

# Copy scripts and change ownership
COPY --chown=buildpiper:buildpiper build.sh /home/buildpiper/
COPY --chown=buildpiper:buildpiper getDynamicVars.sh /home/buildpiper/
COPY --chown=buildpiper:buildpiper BP-BASE-SHELL-STEPS /opt/buildpiper/shell-functions/

# Set working directory
WORKDIR /home/buildpiper

# Make scripts executable
RUN chmod +x build.sh getDynamicVars.sh

# Environment variables (fixed format)
ENV NEW_SERVICE_ACCOUNT=""
ENV SLEEP_DURATION=5s
ENV ACTIVITY_SUB_TASK_CODE=BP-DEPLOYMENT-MANIFEST-EDITOR
ENV VALIDATION_FAILURE_ACTION=WARNING

# Switch to non-root user
USER buildpiper

# Entrypoint
ENTRYPOINT ["./build.sh"]
