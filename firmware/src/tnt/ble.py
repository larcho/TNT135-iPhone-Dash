"""BLE GATT peripheral (aioble). UUIDs must match protocol/README.md."""

import json

import aioble
import bluetooth

SERVICE_UUID = bluetooth.UUID("5A463AEF-3E50-422C-BB65-71823EAA941A")
TELEMETRY_UUID = bluetooth.UUID("E2362505-5861-44DD-A02D-186F6B8750F3")
DEVICE_INFO_UUID = bluetooth.UUID("8B66B202-1392-4644-9FB1-650EDD5C4F19")

_ADV_INTERVAL_US = 100_000


class TelemetryPeripheral:
    def __init__(self, name, device_info):
        self._name = name
        service = aioble.Service(SERVICE_UUID)
        self._telemetry = aioble.Characteristic(service, TELEMETRY_UUID, read=True, notify=True)
        aioble.Characteristic(
            service, DEVICE_INFO_UUID, read=True, initial=json.dumps(device_info).encode()
        )
        aioble.register_services(service)
        self.connected = False

    def publish(self, packet):
        # send_update notifies every subscribed central; a no-op when nobody is.
        self._telemetry.write(packet, send_update=True)

    async def advertise_forever(self):
        while True:
            async with await aioble.advertise(
                _ADV_INTERVAL_US, name=self._name, services=[SERVICE_UUID]
            ) as connection:
                self.connected = True
                await connection.disconnected(timeout_ms=None)
                self.connected = False
