#!/bin/bash

# This script cleans up the directory for all state files

rm -rf *.plan
rm -rf .terraform*
rm -rf *.lock.hcl
rm -rf *.tfstate*
rm -rf *.pem
