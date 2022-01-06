#!/usr/bin/env bash

set -x

echo "This is a setup stage. You can add your custom settings in this stage."

echo "scripts/setup.sh"
cd ..

export BACKEND=$(get_env "multi-tenancy-backend")
echo $BACKEND
git clone $BACKEND
save_repo multi-tenancy-backend "url=${BACKEND}"

export FRONTEND=$(get_env "multi-tenancy-frontend")
echo $FRONTEND
git clone $FRONTEND
save_repo multi-tenancy-frontend "url=${FRONTEND}"

#export PARENT=$(get_env "multi-tenancy")
#echo $PARENT
#git clone $PARENT
#save_repo multi-tenancy "url=${PARENT}"
