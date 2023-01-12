import subprocess


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
        bufsize=1,
        universal_newlines=True,
        shell=True,
    ) as p:
        for line in p.stdout:
            output += line
            if not silent:
                print(line, end="")
        assert p.wait() == 0, "command has failed"
    return output.strip()
