#!/bin/sh

#  e2sgen.sh
#  objcE2S
#
#  Created by Push Chen on 12/2/13.
#  Copyright (c) 2013 Push Chen. All rights reserved.
e2sFile=${PROJECT_NAME}/PYE2S.m
LOG=/tmp/e2s.log
ALL_FRAMEWORK_PATH=$(xcodebuild -version -sdk 2>/dev/null | grep -E "^Path:" | grep -v MacOSX | awk '{print $2}' | head -n 1)/System/Library/Frameworks
FRAMEWORK_NAMES=$(ls $ALL_FRAMEWORK_PATH | grep ".framework" | tr -d '/')

importSL=$(grep --line-number "//-BEGIN-IMPORT-//" $e2sFile | cut -d : -f 1)
importEL=$(grep --line-number "//-END-IMPORT-//" $e2sFile | cut -d : -f 1)

cat $e2sFile | head -n $importSL > ${e2sFile}.tmp
for framework in $FRAMEWORK_NAMES; do
    purgeFramework=$(echo $framework | cut -d . -f 1)
    isPY=$(echo $purgeFramework | grep -E "^PY.*$" | wc -l)
    if [ $isPY -eq 1 ]; then
        continue
    fi
    isQT=$(echo $purgeFramework | grep -E "^QT.*$" | wc -l)
    if [ $isQT -eq 1 ]; then
        continue
    fi
    if [ -f ${ALL_FRAMEWORK_PATH}/$framework/Headers/${purgeFramework}.h ]; then
        echo "#import <$purgeFramework/$purgeFramework.h>" >> ${e2sFile}.tmp
    else
        if [ ! -d ${ALL_FRAMEWORK_PATH}/$framework/Headers ]; then
            continue
        fi
        hfile=$(ls ${ALL_FRAMEWORK_PATH}/$framework/Headers/ | grep ".h")
        for f in $hfile; do
            echo "#import <$purgeFramework/$f>" >> ${e2sFile}.tmp
        done
    fi
done

lineCount=$(cat $e2sFile | wc -l)
trimLineNum=$(($importEL-1))
resetLineCount=$(($lineCount-$trimLineNum))
echo $lineCount, $trimLineNum, $resetLineCount >> $LOG
cat $e2sFile | tail -n $resetLineCount >> ${e2sFile}.tmp
mv ${e2sFile}.tmp ${e2sFile}
