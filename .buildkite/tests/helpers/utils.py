import subprocess
import os


def cmd(commands, silent=False):
    if isinstance(commands, str):
        commands = commands.split(" ")
    output = ""
    cmd_as_string = " ".join(commands)
    if not silent:
        print("Doing cmd: {}".format(cmd_as_string))
    with subprocess.Popen(
            cmd_as_string,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            bufsize=1,
            universal_newlines=True,
            shell=True,
    ) as p:
        for line in p.stdout:
            output += line
            if not silent:
                print(line, end="")
    return output.strip(), p.wait()


def get_filename_as_cluster_name(filepath):
    base_name = os.path.basename(filepath)  # Get the base name of the file
    file_name_without_ext = os.path.splitext(base_name)[0]  # Remove the extension
    return file_name_without_ext.replace("_", "-")
