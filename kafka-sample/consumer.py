from confluent_kafka import Consumer, KafkaError
import signal

# Handle CTRL-C to close connections
def handler(signum, frame):
    print("Closing connections")
    # close the consumer
    c.close()
    # close the OJAI connection
    connection.close()
    print("{} messages processed".format(index))
    exit(0)

signal.signal(signal.SIGINT, handler)

from mapr.ojai.storage.ConnectionFactory import ConnectionFactory
import json
import os

# Create a connection to the table via OJAI
connection_str = "demo.df.io:5678?auth=basic;user=mapr;password=mapr;" \
    "ssl=true;" \
    "sslCA=/opt/mapr/conf/ssl_truststore.pem;" \
    "sslTargetNameOverride=ip-172-31-24-200.eu-west-2.compute.internal"
connection = ConnectionFactory.get_connection(connection_str=connection_str)

# Get a store and assign it as a DocumentStore object
if connection.is_store_exists('/user/mapr/mytable'):
    store = connection.get_store('/user/mapr/mytable')
else:
    store = connection.create_store('/user/mapr/mytable')

def updateTable(json_dict):
    data = json.loads(json_dict)
    # Create new document from json_document
    new_document = connection.new_document(dictionary=data)
    # Print the OJAI Document
    # print(new_document.as_json_str())

    # Insert the OJAI Document into the DocumentStore
    store.insert_or_replace(new_document)
    # create psudo file
    os.system("hadoop fs -touchz myfiles/{}".format(data['file_path']))
    # Hadoop fs commands are too slow to process, instead fuse client access can be used - not available on M1
    # os.system("sudo -u mapr touch /mapr/demo.df.io/user/mapr/myfiles/{}".format(data['file_path']))


# Subscribe to the topic
c = Consumer({'group.id': 'mygroup',
              'default.topic.config': {'auto.offset.reset': 'earliest'}})
c.subscribe(['/user/mapr/mystream:mytopic'])

index = 0
running = True
print('polling topic for messages')

while running:
  msg = c.poll(timeout=1.0)
  if msg is None: continue
  if not msg.error():
    data = msg.value().decode('utf-8')
    print('Received message: %s' % data)
    updateTable(data)
    index += 1
  elif msg.error().code() != KafkaError._PARTITION_EOF:
    print(msg.error())
    running = False

