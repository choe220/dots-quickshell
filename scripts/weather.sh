#!/bin/bash
CITY=$(curl -s ipinfo.io/city)
WEATHER=$(curl -s "wttr.in/$CITY?format=j1")
echo "$CITY: $WEATHER"