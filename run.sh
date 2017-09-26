NETWORK_NAME='local-kafka-net'
NODE_NAME='local-kafka-node'
ZK_NAME='local-kafka-zk'
BROKERS=1

NETWORK_IP_RANGE='172.39.39.0/24'
NODE_IP_PREFIX='172.39.39.1'
ZK_IP='172.39.39.200'

echo 'Deleting existing docker containers...'
for i in `seq 1 $BROKERS`; do
  docker rm -f "$NODE_NAME-$i"
done
docker rm -f "$ZK_NAME"
echo 'Deleting existing docker network...'
docker network rm "$NETWORK_NAME"

echo 'Building docker images...'
NODE_CONTAINER_ID=$( \
  docker build -t "$NODE_NAME" ./kafka-node/ | \
  tee /dev/tty)
ZK_CONTAINER_ID=$( \
  docker build -t "$ZK_NAME" ./zookeeper/ | \
  tee /dev/tty)

NODE_CONTAINER_ID=$(echo "$NODE_CONTAINER_ID" | awk '/^Successfully built/ {print $3}')
ZK_CONTAINER_ID=$(echo "$ZK_CONTAINER_ID" | awk '/^Successfully built/ {print $3}')

echo 'Creating new docker network...'
echo "Network ID: $( \
  docker network create \
    --subnet "$NETWORK_IP_RANGE" \
    "$NETWORK_NAME")"

echo 'Running docker containers...'
for i in `seq 1 $BROKERS`; do
  cat kafka-node/server.properties | \
    sed "s/broker.id=0/broker.id=$i/" | \
    sed "s/172.39.39.11/$NODE_IP_PREFIX$i/" > \
    "kafka-node/server.$i.properties"
    # sed "s/9092/909$i/" | \
  echo "Kafka node container ID: $( \
    docker run -dit \
      --name "$NODE_NAME-$i" \
      --net "$NETWORK_NAME" \
      --ip "$NODE_IP_PREFIX$i" \
      -v "$(pwd)/kafka-node/server.$i.properties:/usr/share/kafka_2.11-0.11.0.1/config/server.properties" \
      -p "9092:9092" \
      "$NODE_CONTAINER_ID")"
      # -p "909$i:909$i" \
done
echo "Zookeeper container ID: $( \
  docker run -dit \
  --name "$ZK_NAME" \
  --net "$NETWORK_NAME" \
  --ip "$ZK_IP" \
  -p 2181:2181 \
  "$ZK_CONTAINER_ID")"

