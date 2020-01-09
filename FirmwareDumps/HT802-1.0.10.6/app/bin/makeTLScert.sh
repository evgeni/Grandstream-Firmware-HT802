#!/bin/sh

CA_FILE=ca_certs.pem
CA_DIR=/tmp/ssl/

if [ ! -d $CA_DIR ]; then
	mkdir $CA_DIR
fi

nvram get 2386 >> $CA_DIR/$CA_FILE
nvram get 2486 >> $CA_DIR/$CA_FILE
nvram get 2586 >> $CA_DIR/$CA_FILE
nvram get 2686 >> $CA_DIR/$CA_FILE
