#!/bin/sh

swift format --in-place --recursive .
swift format lint --recursive .
