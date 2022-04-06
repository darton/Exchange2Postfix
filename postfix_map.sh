#!/usr/bin/env bash

SCRIPT_DIR=/root/skrypty
EXLIST_DIR=/home/user/exchange
FILENAME=email_exchangehostname.txt
FILEHASH=email_exchangehostname.hash

POSTFIX_DIR=/etc/postfix
POSTFIX_RELAY_RECIPIENTS_FILE=relay_recipients
RELAY_RECIPIENTS_FILE=recipients

NOT_ALLOWED_DOMAINS_FILE=notallowed_domains
ALLOWED_DOMAINS_FILE=allowed_domains
NOT_ALLOWED_EMAILS_FILE=notallowed_emails

POSTFIX_MAP_LOGFILE=/var/log/postfix_map.log

function extract_valid_recipients {
    awk -F\" '{if(NR>2 && NF>1) print $2}' $1 \
        |grep -f $SCRIPT_DIR/$ALLOWED_DOMAINS_FILE |grep -f $SCRIPT_DIR/$NOT_ALLOWED_EMAILS_FILE -v \
        |grep -v -f $SCRIPT_DIR/$NOT_ALLOWED_DOMAINS_FILE \
        |sort -u > $2
}

current_time=$(date '+%Y-%m-%d %H:%M:%S')

[[ -f $SCRIPT_DIR/$ALLOWED_DOMAINS_FILE ]] || touch $SCRIPT_DIR/$ALLOWED_DOMAINS_FILE
[[ -f $SCRIPT_DIR/$NOT_ALLOWED_DOMAINS_FILE ]] || touch $SCRIPT_DIR/$NOT_ALLOWED_DOMAINS_FILE
[[ -f $SCRIPT_DIR/$NOT_ALLOWED_EMAILS_FILE ]] || touch $SCRIPT_DIR/$NOT_ALLOWED_EMAILS_FILE

if [ ! -s $EXLIST_DIR/$FILEHASH ] || [ ! -s $EXLIST_DIR/$FILENAME ] ; then

    if [ -f $EXLIST_DIR/$FILEHASH ] ; then
         rm $EXLIST_DIR/$FILEHASH
    fi
    if [ -f $EXLIST_DIR/$FILENAME ] ; then
        rm $EXLIST_DIR/$FILENAME
    fi

    echo "$current_time -File $EXLIST_DIR/$FILEHASH or $EXLIST_DIR/$FILENAME does not exits or is empty!"
    exit 0
fi

HASH1=$(cat $EXLIST_DIR/$FILEHASH|awk '{print $1}'|sed '1s/^\xEF\xBB\xBF//'|tr -d '\r')
HASH2=$(sha256sum $EXLIST_DIR/$FILENAME|awk '{print $1}'|tr a-z A-Z)

if [ "$HASH1" == "$HASH2" ]; then

    extract_valid_recipients $EXLIST_DIR/$FILENAME $SCRIPT_DIR/$RELAY_RECIPIENTS_FILE

    if [ $? == 0 ]; then

        if [ -s "$SCRIPT_DIR/$RELAY_RECIPIENTS_FILE" ]; then
            cat $SCRIPT_DIR/$RELAY_RECIPIENTS_FILE |sort -u |awk -F"@" '{print $0"\tOK"}' > $POSTFIX_DIR/$POSTFIX_RELAY_RECIPIENTS_FILE
        fi

        if [ -s "$POSTFIX_DIR/$POSTFIX_RELAY_RECIPIENTS_FILE" ]; then
            /usr/sbin/postmap hash:$POSTFIX_DIR/$POSTFIX_RELAY_RECIPIENTS_FILE
            echo "$current_time - New relay_recipients was added to Postfix" | tee -a $POSTFIX_MAP_LOGFILE
        else
            echo "$current_time - File $POSTFIX_DIR/relay_recipients does not exits or is empty!" | tee -a $POSTFIX_MAP_LOGFILE
        fi

        git_log

        echo "Done!"
    else
        echo "Can not extract valid recipients from $EXLIST_DIR/$FILENAME" | tee -a $POSTFIX_MAP_LOGFILE

    fi
else
    echo "File does not exist, is empty or downloaded File checksum does not match!" | tee -a $POSTFIX_MAP_LOGFILE

fi

[[ ! -f $EXLIST_DIR/$FILEHASH ]] || rm -f $EXLIST_DIR/$FILEHASH
[[ ! -f $EXLIST_DIR/$FILENAME ]] || rm -f $EXLIST_DIR/$FILENAME
[[ ! -f $SCRIPT_DIR/$RELAY_RECIPIENTS_FILE ]] || rm -f $SCRIPT_DIR/$RELAY_RECIPIENTS_FILE

exit 0
