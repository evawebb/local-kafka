FROM fedora:latest

RUN dnf install -y java nc procps

RUN cd /tmp && curl -O http://apache.cs.utah.edu/zookeeper/zookeeper-3.4.10/zookeeper-3.4.10.tar.gz && cd /
RUN tar -xvf /tmp/zookeeper-3.4.10.tar.gz -C /usr/share/
COPY zoo.cfg /usr/share/zookeeper-3.4.10/conf/

ENTRYPOINT /usr/share/zookeeper-3.4.10/bin/zkServer.sh start-foreground 


