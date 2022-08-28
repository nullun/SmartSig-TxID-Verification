#!/usr/bin/env bash

set -e -u -x

SB="$HOME/sandbox/sandbox"
GOAL="${SB} goal"

ADDR=$(${GOAL} account list | head -n 1 | awk '{print $3}' | tr -d '\r')

${SB} copyTo approval.teal
${SB} copyTo clear.teal

# Deploy App
APP_ID=$(${GOAL} app create \
  --creator ${ADDR} \
  --approval-prog approval.teal \
  --clear-prog clear.teal \
  --global-byteslices 0 --global-ints 0 \
  --local-byteslices 0 --local-ints 0 \
  | grep 'Created app with app index' \
  | awk '{print $6}' \
  | tr -d '\r')
APP_ADDR=$(${GOAL} app info \
  --app-id ${APP_ID} \
  | grep 'Application account' \
  | awk '{print $3}' \
  | tr -d '\r')

# Create Future Atomic Group
${GOAL} clerk send \
  --from ${ADDR} \
  --to ${ADDR} \
  --amount 0 \
  --note "This TxID must be confirmed in a smart sig" \
  -o 0_known.txn
${GOAL} clerk send \
  --from ${APP_ADDR} \
  --to ${APP_ADDR} \
  --amount 0 \
  -o 1_verify.txn
${SB} copyFrom 0_known.txn
${SB} copyFrom 1_verify.txn
cat 0_known.txn 1_verify.txn > group.ctxn
${SB} copyTo group.ctxn
rm 0_known.txn 1_verify.txn group.ctxn
${GOAL} clerk group -i group.ctxn -o group.gtxn
${GOAL} clerk split -i group.gtxn -o group.txn
${SB} copyFrom group-0.txn
TxID=$(python3 txid.py)

cat smart_sig_tmpl.teal | sed "s/__TxID__/${TxID}/g" > smart_sig.teal
${SB} copyTo smart_sig.teal
rm group-0.txn smart_sig.teal
SIG_ADDR=$(${GOAL} clerk compile -n smart_sig.teal \
  | grep 'smart_sig.teal' \
  | awk '{print $2}' \
  | tr -d '\r')

# Sign Group
${GOAL} clerk sign -i group-0.txn -o group-0.stxn
${GOAL} clerk sign -i group-1.txn -o group-1.stxn -p smart_sig.teal -S ${SIG_ADDR}
${SB} copyFrom group-0.stxn
${SB} copyFrom group-1.stxn
cat group-0.stxn group-1.stxn > group.stxn
${SB} copyTo group.stxn
rm group-0.stxn group-1.stxn group.stxn

# Fund App
${GOAL} clerk send \
  --from ${ADDR} \
  --to ${APP_ADDR} \
  --amount 1000000

# Rekey App to SmartSig
${GOAL} app call \
  --from ${ADDR} \
  --app-id ${APP_ID} \
  --app-arg "str:rekey" \
  --app-account ${SIG_ADDR} \
  --fee 2000

# Submit Group
${GOAL} clerk rawsend -f group.stxn

