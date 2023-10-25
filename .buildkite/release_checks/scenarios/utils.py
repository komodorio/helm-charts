import asyncio
import os


async def cmd(commands, silent=True):
    if isinstance(commands, str):
        commands = commands.split(" ")
    cmd_as_string = " ".join(commands)
    if not silent:
        print(f"Doign cmd: {cmd_as_string}")

    process = await asyncio.create_subprocess_shell(
        cmd_as_string,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.STDOUT,
    )

    stdout, _ = await process.communicate()

    output = stdout.decode().strip()
    if not silent:
        print(output)

    return output, process.returncode
