# kamailio/Dockerfile
FROM ghcr.io/kamailio/kamailio-ci:6.0.3-alpine

# Copy configuration
COPY kamailio.cfg /etc/kamailio/kamailio.cfg
COPY kamctlrc /etc/kamailio/kamctlrc

# Expose SIP ports
EXPOSE 5060/udp 5060/tcp 5061/tcp

# Base image already has ENTRYPOINT ["kamailio", "-DD", "-E"]
# which runs Kamailio in foreground with logs to stderr
