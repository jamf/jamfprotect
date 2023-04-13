#!/bin/sh

tmpdir=$(/usr/bin/mktemp -d)

createJPEventAnalysis () {
cat << EOF > "$tmpdir"/jp_event_analysis.py
#!/usr/bin/env python3

import json, re, subprocess, pandas as pd, argparse, numpy as np, logging, signal, os, warnings, psutil

warnings.simplefilter(action="ignore", category=FutureWarning)
from subprocess import Popen, PIPE, TimeoutExpired


def unified_log(
    MONITOR,
    INPUT,
):
    if INPUT:
        # Log stream adds an extra line so check first if JSON is valid
        try:
            with open(INPUT) as j:
                json_array = json.load(j)
        except json.decoder.JSONDecodeError as e:
            print("JSON object issue, removing first line.")
        else:
            return json_array

        # Otherwise remove the first line and proceed
        with open(INPUT, "r+") as j:
            lines = j.readlines()
            j.seek(0)
            j.truncate()
            j.writelines(lines[1:])

        with open(INPUT) as j:
            json_array = json.load(j)

        return json_array
    else:
        print(f"Running {MONITOR} log stream for the next 60 seconds...")

        with Popen(
            f'log stream --info --debug --style json --predicate \'subsystem BEGINSWITH "com.jamf.protect" AND category == "{MONITOR}"\'',
            shell=True,
            stdout=PIPE,
            preexec_fn=os.setsid,
            encoding="utf-8",
            universal_newlines=True,
        ) as process:
            try:
                output = process.communicate(timeout=60)[0]
            except TimeoutExpired:
                os.killpg(
                    process.pid, signal.SIGINT
                )  # Send signal to the process group
                output = process.communicate()
        o = "\n".join(output[0].split("\n")[1:])
        json_array = json.loads(o)
        return json_array


c = {}


def codesign(items):
    """Use the codesign command to get TeamIdentifier or Identifier, which can be used to
    set exceptions in Jamf Protect."""
    cmd = f"/usr/bin/codesign -dv '{items}' 2>&1 | awk -F'=' '/TeamIdentifier/ {{print $2}}'"
    process = subprocess.Popen(cmd, stdout=subprocess.PIPE, shell=True)
    process.wait()
    output, error = process.communicate()
    if "not set" in output.decode("utf-8").strip():
        cmd = f"/usr/bin/codesign -dv '{items}' 2>&1 | awk -F'=' '/Identifier/ {{print $2}}'"
        process = subprocess.Popen(cmd, stdout=subprocess.PIPE, shell=True)
        process.wait()
        output, error = process.communicate()
    codesignInfo = items + " " + output.decode("utf-8").strip().replace("\nnot set", "")
    if codesignInfo not in c.keys():
        c[codesignInfo] = {}
        c[codesignInfo]["Binary"] = items
        c[codesignInfo]["Signing Info"] = (
            output.decode("utf-8").strip().replace("\nnot set", "")
        )
    return c


def table(d, monitor, output, cs=""):
    """Create a Pandas DataFrame which is used to display total event counts per Jamf Protect Monitor."""
    args = create_args()

    if output:
        out_path = f"{output}/{monitor}.xlsx"
        writer = pd.ExcelWriter(out_path, engine="xlsxwriter")
    else:
        writer = pd.ExcelWriter(f"{monitor}.xlsx", engine="xlsxwriter")

    if monitor == "ExecAuth" or monitor == "Process":
        df = pd.DataFrame(d)
    else:
        df = pd.DataFrame(d, index=["count"])

    df = df.replace(np.nan, "", regex=True)

    # Removes first column for Threat Prevention and Process Events since we break this out into invidual columns
    if monitor == "ExecAuth" or monitor == "Process":
        df.columns = [""] * len(df.columns)

    df = df.T.sort_values(by="count", ascending=False)

    df.to_excel(writer, sheet_name="Sheet1")

    if args.summary:
        print(f"Top 10 Count for {monitor} Monitor")
        print(df.head(n=10))

    # Add codesign info for Threat Prevent and Process Events
    if monitor == "ExecAuth" or monitor == "Process":
        df2 = pd.DataFrame(cs)

        df2.columns = [""] * len(df2.columns)
        df2 = df2.T

        if args.summary:
            print(f"\nUnique Codesigning Info")
            print(df2)

        df2.to_excel(writer, sheet_name="Sheet1", startcol=4)

    writer.close()

    print(f"\nSee excel spreadsheet for full report.")


def create_args():
    parser = argparse.ArgumentParser(
        description="Given a monitor, count events in Unified Logs."
    )
    parser.add_argument(
        "-m",
        "--monitor",
        default=None,
        help="monitor name to be used when parsing the logs",
        required=True,
    )
    parser.add_argument(
        "-i",
        "--input",
        default=None,
        help="path to JSON file to be parsed",
        required=False,
    )
    parser.add_argument(
        "-o",
        "--output",
        default=None,
        help="path to save xlsx",
        required=False,
    )
    parser.add_argument(
        "-s",
        "--summary",
        default=None,
        help="print summary",
        required=False,
        action="store_true",
    )
    parser.add_argument(
        "-d",
        "--debug",
        default=None,
        help=argparse.SUPPRESS,
        action="store_true",
    )
    return parser.parse_args()


def __main__():

    args = create_args()
    if args.debug:
        logging.basicConfig(level=logging.DEBUG)
    else:
        logging.basicConfig(level=logging.WARNING)

    INPUT = args.input

    MONITOR = args.monitor

    OUTPUT = args.output

    if (
        MONITOR == "ExecAuth"
        or MONITOR == "Process"
        or MONITOR == "File"
        or MONITOR == "UnifiedLogging"
    ):

        d = {}
        binaries = []
        ppid = []

        json_array = unified_log(
            MONITOR,
            INPUT,
        )
        if MONITOR == "Process":
            for i in json_array:
                if "Checking: EXEC:" in i["eventMessage"]:
                    logging.debug(i["eventMessage"])
                    parent = re.search(
                        r"EXEC\:\s\(?\D\d*\)\s(\S+\s.*)\-\>", i["eventMessage"]
                    )
                    args = re.search(r"\(\d*\)\s(\W.*)", i["eventMessage"])
                    pid = re.search(r"EXEC\:\s\((.\d*)\)", i["eventMessage"])
                    if not pid.group(1) == "-1":
                        command = (
                            pid.group(1) + " " + parent.group(1) + " " + args.group(1)
                        )
                        if command in d.keys():
                            count = d[command]["count"]
                            count += 1
                            d[command]["count"] = count
                        else:
                            d[command] = {}
                            d[command]["count"] = 1
                            d[command]["pid"] = pid.group(1)
                            d[command]["parent"] = parent.group(1)
                            d[command]["args"] = args.group(1)
                            ppid.append(d[command]["pid"])

            # Use set to get unique parent process pid
            set_bin = set(ppid)
            list_bin = list(set_bin)

            # Use psutil to grab process path and call codesign function
            for items in list_bin:
                try:
                    a_path = psutil.Process(int(items)).exe()
                except psutil.NoSuchProcess as e:
                    pass
                else:
                    cs = codesign(a_path)

            if d == {}:
                print("No events found")
            else:
                table(d, MONITOR, OUTPUT, cs)

        elif MONITOR == "ExecAuth":
            for i in json_array:
                if "Checking: Pid:" in i["eventMessage"]:
                    logging.debug(i["eventMessage"])
                    parent = re.search(
                        r"(Parent\:\s(.*)\sArgs\:|Parent\:\s(\S*)\s?)",
                        i["eventMessage"],
                    )
                    args = re.search(r"Args\:\s(\S*\s?.+)", i["eventMessage"])
                    if args == None:
                        command = parent.group(3)
                    else:
                        command = parent.group(2) + " " + args.group(1)
                    if command in d.keys():
                        count = d[command]["count"]
                        count += 1
                        d[command]["count"] = count
                    else:
                        d[command] = {}
                        d[command]["count"] = 1
                        if args == None:
                            d[command]["parent"] = parent.group(3)
                            binaries.append(d[command]["parent"])
                        else:
                            d[command]["parent"] = parent.group(2)
                            d[command]["args"] = args.group(1)
                            binaries.append(d[command]["parent"])

            # Use set to get unique process name
            set_bin = set(binaries)
            list_bin = list(set_bin)

            for items in list_bin:
                try:
                    cs = codesign(items)
                except:
                    pass

            if d == {}:
                print("No events found")
            else:
                table(d, MONITOR, OUTPUT, cs)

        elif MONITOR == "File":
            for i in json_array:
                if (
                    "Checking: Created Path:" in i["eventMessage"]
                    or "Checking: Modified Path:" in i["eventMessage"]
                    or "Checking: Deleted Path:" in i["eventMessage"]
                    or "Checking: Renamed Path:" in i["eventMessage"]
                ):
                    logging.debug(i["eventMessage"])
                    file = re.search(r"\D\: (.*)\sPid", i["eventMessage"])
                    command = file.group(1)
                    if command in d.keys():
                        count = d[command]
                        count += 1
                        d[command] = count
                    else:
                        d[command] = 1
            if d == {}:
                print("No events found")
            else:
                table(d, MONITOR, OUTPUT)

        elif MONITOR == "UnifiedLogging":
            for i in json_array:
                if "Found match(s):" in i["eventMessage"]:
                    logging.debug(i["eventMessage"])
                    ul = re.search(r"\D\:\s(.*)", i["eventMessage"])
                    try:
                        if not "AUE" in ul.group(1):
                            command = ul.group(1)
                            if command in d.keys():
                                count = d[command]
                                count += 1
                                d[command] = count
                            else:
                                d[command] = 1
                    except:
                        pass

            if d == {}:
                print("No events found")
            else:
                table(d, MONITOR, OUTPUT)
    else:
        print("Monitor must be ExecAuth, Process, File, or UnifiedLogging")
        return


if __name__ == "__main__":

    __main__()

EOF

/bin/chmod +x "$tmpdir"/jp_event_analysis.py
}

ConfigurePython () {
    python3 -m venv "$tmpdir"/virtenv
    source "$tmpdir"/virtenv/bin/activate
    pip3 --no-cache-dir install pandas openpyxl xlsxwriter psutil
}

gatherLogs () {
    /usr/local/bin/protectctl info -v > /var/tmp/protectInfo.txt
    python3 "$tmpdir"/jp_event_analysis.py -m ExecAuth -o /var/tmp
    python3 "$tmpdir"/jp_event_analysis.py -m Process -o /var/tmp
    python3 "$tmpdir"/jp_event_analysis.py -m File -o /var/tmp 
    python3 "$tmpdir"/jp_event_analysis.py -m UnifiedLogging -o /var/tmp 

    echo "zip up xlsx files in"
    /usr/bin/zip -j /var/tmp/output.zip /var/tmp/*.xlsx /var/tmp/protectInfo.txt

}

cleanup () {
    echo "Cleaning up"
    /bin/rm /var/tmp/*.xlsx
    /bin/rm /var/tmp/protectInfo.txt

    deactivate

    /bin/rm -rf "$tmpdir"
}

createJPEventAnalysis
ConfigurePython
gatherLogs
cleanup

/usr/bin/open /var/tmp