This repository demonstrates how to rekey a smart contract to a smart signature, so that you can create an atomic group, place the TxID of a transaction from within the group into the smart signature, then only allow the group to be submitted if that transaction is included in the group.

Make sure sandbox is running *on a private network* and you have py-algorand-sdk installed for `txid.py`

`./test.sh` gives a complete run through.

