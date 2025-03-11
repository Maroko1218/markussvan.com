#!/bin/bash
cd /home/Tabor/websites/markussvan.com/
chown -R root:root .
hugo --cleanDestinationDir -d /srv/http/markussvan.com
chown -R Tabor:Tabor .