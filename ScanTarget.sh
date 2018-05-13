#!/bin/bash
#
# OpenVAS automation script.

trap ctrl_c INT

# --- CONFIGURATION ---

USER=admin
PASS=admin
HOST=127.0.0.1
PORT=9390

SCAN_PROFILE="Full and very deep ultimate"

FORMAT="XML"

ALIVE_TEST='ICMP, TCP-ACK Service &amp; ARP Ping'

# --- END OF CONFIGURATION ---

enable_to_clean=1

function omp_cmd {
        cmd="omp -u $USER -w $PASS -h $HOST -p $PORT $@"
        eval $cmd 2>&1
}

function omp_cmd_xml {
        omp_cmd "--xml='$@'"
}

function end {
        echo "[>] Performing cleanup"

        if [ $able_to_clean -eq 1 ]; then
                omp_cmd -D $task_id
                omp_cmd -X '<delete_target target_id="'$target_id'"/>'
  	fi
        exit 1
}

function ctrl_c() {
        echo "[?] CTRL-C trapped."
        exit 1
        end
}

out=$(omp_cmd -g)

if [ -z "$out" ]; then
        echo "Exiting due to OpenVAS authentication failure."
        exit 1
fi

scan_profile_id=74db13d6-7489-11df-91b9-002264764cea

format_id=a994b278-1f62-11e1-96ac-406186ea4fc5

TARGET="$1"
host "$TARGET" 2>&1 > /dev/null

echo "[+] Tasked: '$SCAN_PROFILE' scan against '$TARGET' "

target_id=$(omp_cmd -T | grep "$TARGET" | cut -d' ' -f1)

out=""
if [ -z "$target_id" ]; then

        echo "[>] Creating a target..."
        out=$(omp -u $USER -w $PASS -h $HOST -p $PORT --xml=\
"<create_target>\
<name>${TARGET}</name><hosts>$TARGET</hosts>\
<alive_tests>$ALIVE_TEST</alive_tests>\
</create_target>")
        target_id=$(echo "$out" | pcregrep -o1 'id="([^"]+)"')

else
	echo "[>] Reusing target..."
fi

if [ -z "$target_id" ]; then
        echo "[!] Something went wrong, couldn't acquire target's ID! Output:"
        echo $out
        exit 1
else
        echo "[+] Target's id: $target_id"
fi

echo "[>] Creating a task..."
task_id=$(omp_cmd -C -n "$TARGET" --target=$target_id --config=$scan_profile_id)

if [ $? -ne 0 ]; then
        echo "[!] Could not create a task."
        end
fi

echo "[+] Task created successfully, id: '$task_id'"

echo "[>] Starting the task..."
report_id=$(omp_cmd -S $task_id)

if [ $? -ne 0 ]; then
        echo "[!] Could not start a task."
        end
fi

able_to_clean=0

echo "[+] Task started. Report id: $report_id"
echo "[.] Awaiting for it to finish. This will take a long while..."
echo

aborted=0
while true; do
    RET=$(omp_cmd -G)

    RET=$(echo -n "$RET" | grep -m1 "$task_id" | tr '\n' ' ')
    out=$(echo "$RET" | tr '\n' ' ')
        echo -ne "$out\r"
    if [ `echo "$RET" | grep -m1 -i "fail"` ]; then
                        echo '[!] Failed getting running jobs list'
                        end
        fi
    echo "$RET" | grep -m1 -i "stopped"
    if [ $? -eq 0 ]; then
        aborted=1
        break
    fi
        echo "$RET" | grep -m1 -i "done"
        if [ $? -eq 0 ]; then
                break
        fi
    sleep 1

done

if [ $aborted -eq 0 ]; then
	echo "[+] Job done, generating report..."

        FILENAME=$TARGET

        out=$(omp_cmd --get-report $report_id --format $format_id > $FILENAME.$FORMAT )

        if [ $? -ne 0 ]; then 
                echo '[!] Failed getting report.'; 
                echo "[!] Output: $out"
                #end
        fi

        echo "[+] Scanning done."
else
        echo "[?] Scan monitoring has been aborted. You're on your own now."
fi

