NETWORK_NAME='local-kafka-net'
NODE_NAME='local-kafka-node'
ZK_NAME='local-kafka-zk'
NETWORK_IP_RANGE='172.39.39.0/24'
NODE_IP='172.39.39.2'
ZK_IP='172.39.39.200'

BROKERS=${1:-3}
if [ "$BROKERS" -gt 9 ]; then
  echo 'Warning: the number of brokers cannot exceed 9.'
  BROKERS='9'
fi

echo 'Deleting existing docker containers...'
docker rm -f $(docker ps -aq --filter "name=$NODE_NAME")
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

BROKER_LIST=''

echo 'Running docker containers...'

echo "Zookeeper container ID: $( \
  docker run -dit \
  --name "$ZK_NAME" \
  --net "$NETWORK_NAME" \
  --ip "$ZK_IP" \
  -p 2181:2181 \
  "$ZK_CONTAINER_ID")"

echo 'Waiting for a bit so Zookeeper can start up...'
sleep 10

mkdir kafka-node/broker-properties
mkdir kafka-node/start-scripts
START_SCRIPT=''
BROKER_LIST=''
KAFKA_NODE_ARGS=(
  --name "$NODE_NAME"
  --net "$NETWORK_NAME"
  --ip "$NODE_IP"
  -v "$(pwd)/kafka-node/broker-properties:/usr/share/kafka_2.11-0.11.0.1/config/broker-properties"
  -v "$(pwd)/kafka-node/start-scripts/start.sh:/start.sh"
)

for i in `seq 1 $BROKERS`; do
  cat kafka-node/server.properties | \
    sed "s/broker.id=0/broker.id=$i/" | \
    sed "s/9092/909$i/" | \
    sed "s/kafka-logs/kafka-logs-$i/" | \
    sed "s/172.39.39.11/$NODE_IP/" > \
    "kafka-node/broker-properties/server.$i.properties"

  START_SCRIPT="$START_SCRIPT\n/usr/share/kafka_2.11-0.11.0.1/bin/kafka-server-start.sh /usr/share/kafka_2.11-0.11.0.1/config/broker-properties/server.$i.properties &"
  BROKER_LIST="$BROKER_LIST,localhost:909$i"
  KAFKA_NODE_ARGS+=(-p "909$i:909$i")
done
START_SCRIPT="$START_SCRIPT\ntail -f /dev/null"
echo -e "$START_SCRIPT" > "kafka-node/start-scripts/start.sh"
chmod 755 "kafka-node/start-scripts/start.sh"

echo "Kafka node container ID: $( \
  docker run -dit \
    "${KAFKA_NODE_ARGS[@]}" \
    "$NODE_CONTAINER_ID")"

echo "Broker list: ${BROKER_LIST:1}"
