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
cat $e2sFile | tail -n $resetLineCount >> ${e2sFile}.tmp
mv ${e2sFile}.tmp ${e2sFile}

printSL=$(grep --line-number "//-BEGIN-PRINT-//" $e2sFile | cut -d : -f 1)
printEL=$(grep --line-number "//-END-PRINT-//" $e2sFile | cut -d : -f 1)
cat $e2sFile | head -n $printSL > ${e2sFile}.tmp

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
    if [ ! -d ${ALL_FRAMEWORK_PATH}/$framework/Headers ]; then
        continue
    fi
    cd ${ALL_FRAMEWORK_PATH}/$framework/Headers
    true > /tmp/e2sFile.tmp
    result=$(grep -E "NS_ENUM\(|NS_OPTIONS\(" --line-number *.h | tr '\011' ' ' | tr ' ' '*' )
    for line in $result; do
        file=$(echo $line | awk -F":" '{print $1}')
        num=$(echo $line | awk -F":" '{print $2}')
        linecount=$(cat $file | wc -l)
        leftline=$(($linecount-$num))
        cat $file | tail -n $leftline > /tmp/$file.$leftline
        endline=$(cat /tmp/$file.$leftline | grep "}" --max-count=1 --line-number | awk -F":" '{print $1}')
        unavailableLine=$(cat /tmp/$file.$leftline | grep ", NA)" --line-number --max-count=1 | awk -F":" '{print $1}')
        if [ $unavailableLine ]; then
            if [ $unavailableLine -le $endline ]; then
                rm /tmp/$file.$leftline
                continue
            fi
        fi
        cat /tmp/$file.$leftline | \
            head -n $(($endline-1)) | \
            grep -v "{" |               \
            grep -v "^[[:space:]]*$" |  \
            grep -v -E "^\/*$" |        \
            grep -v "^\*" |             \
            grep -v "^#" |              \
            grep -v "__NSCALENDAR_COND_IOS" | \
            awk '{print $1}' |          \
            cut -d = -f 1 |             \
            tr -d ' ' |                 \
            tr -d '\011' |              \
            tr -d ',' |                 \
            grep -v -E "^When*$" |      \
            grep -v -E "^For*$" |       \
            grep -v -E "^UIFontDescriptorSymbolicTraits*$" | \
            grep -v "NSNumberFormatterBehavior10_0" | \
            grep -v "NSDateFormatterBehavior10_0" | \
            grep -v -E "relative|maximum|\*|all|\/\/|\/\*|\*\/|__has_feature|defined|typedef|@class|FOUNDATION_EXPORT" >> /tmp/e2sFile.tmp
        #echo $endline
        rm /tmp/$file.$leftline
    done
    cd -
    keys=$(cat /tmp/e2sFile.tmp)
    for k in $keys; do 
        echo "    printf(\"$k:%lld\\n\", (int64_t)$k);" >> ${e2sFile}.tmp
    done
done

lineCount=$(cat $e2sFile | wc -l)
trimLineNum=$(($printEL-1))
resetLineCount=$(($lineCount-$trimLineNum))
echo $lineCount, $trimLineNum, $resetLineCount >> $LOG
cat $e2sFile | tail -n $resetLineCount >> ${e2sFile}.tmp
mv ${e2sFile}.tmp ${e2sFile}

