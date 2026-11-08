FROM n8nio/n8n:latest
USER root
RUN mkdir -p /opt/nmap-root && \
    cd /tmp && \
    wget -q https://dl-cdn.alpinelinux.org/alpine/v3.24/main/x86_64/apk-tools-static-3.0.9-r0.apk && \
    tar -xzf apk-tools-static-3.0.9-r0.apk && \
    chmod +x sbin/apk.static && \
    ./sbin/apk.static --no-cache --initdb --allow-untrusted --root /opt/nmap-root --repository https://dl-cdn.alpinelinux.org/alpine/v3.24/main add nmap nmap-scripts && \
    rm -rf /tmp/sbin /tmp/*.apk /tmp/.SIGN* /tmp/.PKGINFO
USER node
ENV LD_LIBRARY_PATH=/opt/nmap-root/usr/lib:/opt/nmap-root/lib
ENV PATH=/opt/nmap-root/usr/bin:$PATH
ENV NMAPDIR=/opt/nmap-root/usr/share/nmap