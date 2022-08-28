#!/usr/bin/env python3

from algosdk import encoding, constants
from algosdk.encoding import base64

with open("group-0.txn", "rb") as f:
    bytes = f.read()
txn = encoding.msgpack_encode(encoding.future_msgpack_decode(base64.b64encode(bytes)))
to_sign = constants.txid_prefix + base64.b64decode(txn)
txid = encoding.checksum(to_sign)
print(f"0x{txid.hex()}")
quit()
txid = base64.b32encode(txid).decode()
print(encoding._undo_padding(txid))

