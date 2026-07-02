#!/bin/bash

pkill -f dashboard.sh || foot --app-id dashboard -e bash $HOME/.config/Scripts/dashboard.sh
