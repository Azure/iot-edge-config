#!/usr/bin/env python


import argparse
import asyncio
import os

from azure.eventhub import EventData
from azure.eventhub.aio import EventHubProducerClient

# prepare the command line arguments parser
parser = argparse.ArgumentParser()
parser.add_argument("connection_string")
parser.add_argument("event_hub")
parser.add_argument("message")

# parse the arguments
arguments = parser.parse_args()

producer = EventHubProducerClient.from_connection_string(
    conn_str=arguments.connection_string,
    eventhub_name=arguments.event_hub
)

async def run():
    # Create a producer client to send messages to the event hub.
    async with producer:
        # Create a batch.
        event_data_batch = await producer.create_batch()

        # Add events to the batch.
        event_data_batch.add(EventData(arguments.message))

        # Send the batch of events to the event hub.
        await producer.send_batch(event_data_batch)

loop = asyncio.get_event_loop()
loop.run_until_complete(run())
