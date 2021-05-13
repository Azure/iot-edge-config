#!/usr/bin/env python3

import argparse
import sys


from azure.iot.device import IoTHubDeviceClient


# prepare the command line arguments parser
parser = argparse.ArgumentParser()
parser.add_argument("connection_string")
parser.add_argument("message")

# parse the arguments
arguments = parser.parse_args()

client = IoTHubDeviceClient.create_from_connection_string(arguments.connection_string)
client.send_message(arguments.message)
print(arguments.message)

client.shutdown()
