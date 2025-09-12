#!/usr/bin/env bash

swww img --transition-type random $(find ~/Pictures -type f | shuf | head -n 1)


