#!/bin/bash
cd /home/Tabor/websites/markussvan.com/ &&\
hugo &&\
rm -rf /srv/http/markussvan.com/* &&\
cp -r public/* /srv/http/markussvan.com/ &&\
chown -R root:root /srv/http/markussvan.com/*
