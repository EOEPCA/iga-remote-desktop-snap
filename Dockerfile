FROM ghcr.io/eoepca/iga-remote-desktop:1.2.0

USER root

RUN apt update && apt-get -y install \
    default-jdk \
    maven \
    wget \
    libgl1-mesa-dri \
    libgl1-mesa-glx \
    libglu1-mesa \
    mesa-utils \
    && rm -rf /var/lib/apt/lists/*

ENV JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64/"

COPY response.varfile /tmp/response.varfile
RUN wget -q -O /tmp/esa-snap_all_unix_9_0.sh \
  "http://step.esa.int/downloads/9.0/installers/esa-snap_all_unix_9_0_0.sh" && \
   sh /tmp/esa-snap_all_unix_9_0.sh -q -varfile /tmp/response.varfile && \
   rm -f /tmp/esa-snap_all_unix_9_0.sh 

ENV PATH=/usr/local/snap/bin:$PATH

RUN chown -R $NB_UID:$NB_GID $HOME

ADD snap.desktop /etc/xdg/autostart/snap.desktop

USER $NB_USER
