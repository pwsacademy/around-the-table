#!/bin/bash
rm -rf ~/Library/Developer/Xcode/DerivedData/AroundTheTable*
rm -rf *.xcodeproj
swift package generate-xcodeproj
open AroundThetable.xcodeproj
