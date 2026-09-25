FROM debian:bookworm-slim

# Install the tools silentknock.sh  needs.
# --no-install-recommends keeps out bloat we don't need.
# Cleaning up apt's cache in the SAME RUN line keeps that layer small —
# if you clean up in a separate RUN, the earlier layer still has the fat baked in.
RUN apt-get update && apt-get install -y --no-install-recommends \
    nmap \
    dnsutils \
    whois \
    netbase \
    bash \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy our script into the image and make it executable
COPY silentknock.sh /usr/local/bin/silentknock.sh
RUN chmod +x /usr/local/bin/silentknock.sh

# This is where /output (from silentknock.sh) will resolve to inside the container
WORKDIR /output

# Create a dedicated non-root user and group, then hand ownership
# of /output to it so the script can still write report files there.
RUN groupadd -r -g 5000 silentknock && useradd -r -u 5000 -g silentknock -d /output -s /usr/sbin/nologin silentknock
RUN chown -R silentknock:silentknock /output

# Switch to that user — everything from here on runs unprivileged.
USER silentknock

# Run our script as the container's main process.
# No default target — the container is useless without an argument on purpose.
ENTRYPOINT ["/usr/local/bin/silentknock.sh"]
