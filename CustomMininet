FROM python:3.8-slim

USER root
WORKDIR /root

COPY utils /root/utils

RUN apt-get update && apt-get install mininet \
 iproute2 \
 iputils-ping \
 mininet \
 net-tools \
 openvswitch-switch \
 openvswitch-testcontroller \
 tcpdump \ 
 -y --no-install-recommends \
 && pip install mininet \
 && chmod +x utils/run.sh

EXPOSE 6633 6653 6640

ENTRYPOINT ["./utils/run.sh"]
