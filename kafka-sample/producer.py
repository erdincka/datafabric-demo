from confluent_kafka import Producer
from random import randint
from time import sleep
import datetime
import json
import signal

# Handle CTRL-C to close connections
def handler(signum, frame):
    print("Closing")
    print("Messages sent: {}".format(index))
    exit(0)

signal.signal(signal.SIGINT, handler)

p = Producer({'streams.producer.default.stream': '/user/mapr/mystream'})
index = 0

while True:
     seq = str(randint(1000000,9999999))
     json_dict = {
          "_id" : seq,
          "title" : "Title {}".format(seq),
          "description" : "Description for document # {}".format(seq),
          "document_date" : str(datetime.datetime.now()),
          "file_path" : "{}.bin".format(seq)
          }
     print('sending {}'.format(json_dict))
     p.produce('mytopic', json.dumps(json_dict).encode('utf-8'))
     p.flush()
     index += 1
     sleep(0.5)
