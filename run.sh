#!/bin/bash
cd /home/Tabor/websites/markussvan.com/ &&\
chown -R root:root .
hugo --cleanDestinationDir &&\
rm -rf /srv/http/markussvan.com/* &&\
cp -r public/* /srv/http/markussvan.com/ &&\
chown -R Tabor:Tabor .