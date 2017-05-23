#!/bin/bash

export ROOT_CA_KEY=private/ca.key
export ROOT_CA_CRT=certs/ca.crt

export INTR_CA_KEY=intermediate/private/intermediate.key
export INTR_CA_CSR=intermediate/private/intermediate.csr
export INTR_CA_CRT=intermediate/certs/intermediate.crt
export INTR_CA_CHAIN_CRT=intermediate/certs/ca-chain.crt

export SUBJECT_BASE="/C=US/ST=California/L=San Jose/O=Example Inc/CN=example.com/OU=CDA"
export PASSWD=123123
