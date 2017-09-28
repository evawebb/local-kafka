FROM fedora:latest

RUN dnf install -y java nc procps socat

RUN cd /tmp && curl -O http://apache.cs.utah.edu/kafka/0.11.0.1/kafka_2.11-0.11.0.1.tgz && cd /
RUN tar -xvf /tmp/kafka_2.11-0.11.0.1.tgz -C /usr/share/

ENTRYPOINT /start.sh
