#!/bin/bash

LAMBDA_ZIP="lambda_package.zip"
LAMBDA_DIR="lambda"

# Remove old package
rm -f $LAMBDA_ZIP

# Install dependencies
pip install -r $LAMBDA_DIR/requirements.txt -t $LAMBDA_DIR

# Create zip package
cd $LAMBDA_DIR
zip -r ../$LAMBDA_ZIP .
cd ..
