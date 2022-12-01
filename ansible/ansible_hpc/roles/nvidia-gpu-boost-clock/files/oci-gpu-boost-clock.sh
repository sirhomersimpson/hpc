#!/bin/bash

if [ ! nvidia-smi ]; then
   echo "nvidia-smi not found"
   exit 0
fi

nvidia-smi --auto-boost-default=0

GPUNAME=$(nvidia-smi --query-gpu=name --format=csv,noheader -i 0)
echo $GPUNAME

MAX_GRAPHICS_CLOCK=$(nvidia-smi -q -d SUPPORTED_CLOCKS -i 0 | grep Graphics | head -1 | cut -d: -f 2 | awk '{print $1}')
MAX_MEMORY_CLOCK=$(nvidia-smi -q -d SUPPORTED_CLOCKS -i 0 | grep Memory | cut -d: -f 2 | awk '{print $1}')

if [ "$MAX_GRAPHICS_CLOCK" == "" ] || [ "$MAX_MEMORY_CLOCK" == "" ]; then
   echo "can't determine maximum clocks"
   exit 0
fi

nvidia-smi -ac ${MAX_MEMORY_CLOCK},${MAX_GRAPHICS_CLOCK}
nvidia-smi -lgc $MAX_GRAPHICS_CLOCK

