#!/bin/bash

#########################################
#                                       #
#   author: Giorgio Cerruti             #
#   mail: giorgio.cerruti@beinnova.it   #
#                                       #
#########################################


CONFIG=config.conf
LOG_FILE=`date +"%Y%m%d%H%M%S"`.log
MISSED=0
TEMPLATE=config.json.template
TEMPLATE_TMP=$TEMPLATE.tmp
OUTPUT_FILE_NAME=$1


function check {

    if [ -z $OUTPUT_FILE_NAME ];then
        echo "ERROR - You must insert file name!" >> $LOG_FILE
        return 1
    fi

    if [[ ! $OUTPUT_FILE_NAME =~ \.json$ ]];then
        OUTPUT_FILE_NAME="$OUTPUT_FILE_NAME.json"
    fi

    if [ ! -f $CONFIG ]; then
        echo "ERROR - The file $CONFIG not found" >> $LOG_FILE
        return 1 
    fi

    if [ ! -f $TEMPLATE ]; then
        echo "ERROR - No template file $TEMPLATE found" >> $LOG_FILE
        return 1
    fi

}


function templetize {

    cp $TEMPLATE $TEMPLATE_TMP

    pat="((^[0-9]+$)|true|false|(^\{))"
    lastPlaceHolder=""

    while IFS='' read -r line || [[ -n "$line" ]]; do
        IFS="=" read -r -a array <<< "$line"

        placeholder=${array[0]}
        value=${array[1]}

        if [ -z "$value" ];then
            prevline=$(( `grep -n "{{$placeholder}}" $TEMPLATE_TMP | awk '{ print $1 }' | sed 's/:$//'` - 1 ))
            sed -i  "${prevline},${prevline}s/\(.*\),/\1/" $TEMPLATE_TMP
            sed -i "/{{$placeholder}}/d" $TEMPLATE_TMP
            echo "No value for param $value" >> $LOG_FILE
            MISSED=$((MISSED +1 ))
            continue 
        fi

        if [[ $value =~ (^\{) ]];then
            for i in $(grep -o "[a-z]*:" <<< $value);do
                value=`sed "s#\"*${i%?}:\"*#\"${i%?}\":#g" <<<$value`
            done
        fi

        if [[ $value =~ $pat ]];then
            sed -i "s#\"{{$placeholder}}\"#$value#g" $TEMPLATE_TMP
        else
            sed -i "s#{{$placeholder}}#$value#g" $TEMPLATE_TMP
        fi


    done < "$CONFIG"

    mv $TEMPLATE_TMP $OUTPUT_FILE_NAME    

}

if check ;then
    templetize
    if [ ! -z $MISSED ];then
        echo "You have $MISSED blanck value in your config. See the log file $LOG_FILE"
    else
        echo "Finish!"
    fi
    exit 0
else
    echo "Some error occurred. See the log file $LOG_FILE"
    exit 1
fi
