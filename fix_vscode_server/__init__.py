import os
import shutil
import subprocess
import logging

logger = logging.getLogger(__name__)


def is_elf(path: str) -> bool:
    with open(path, "rb") as f:
        return f.read(4) == b"\x7FELF"


def fix_vscode_server(
    path: str, *, patchelf: str, interpreter: str, rpath: str, vscode: str
):
    bin_path = os.path.join(path, "bin")

    if not os.path.exists(bin_path):
        logger.error(f"Path does not exist: {bin_path}")
        logger.error("Install vscode server and try again")
        exit(1)

    for dirname in os.listdir(bin_path):
        dirpath = os.path.join(bin_path, dirname)
        if os.path.isdir(dirpath):
            nodepath = os.path.join(dirpath, "node")
            if os.path.islink(nodepath):
                logger.debug(f"Already fixed {dirpath}")
            else:
                shutil.move(nodepath, os.path.join(dirpath, "node_backup"))
                os.symlink("/run/current-system/sw/bin/node", nodepath)
                logger.info(f"Fixed {nodepath}")

    for root, _subdirs, files in os.walk(bin_path):
        for file in files:
            file_path = os.path.join(root, file)
            if file == "spawn-helper":
                logger.warning(f"Overwriting {file_path}")
                patched_spawn_helper = os.path.join(
                    vscode,
                    "lib",
                    "vscode",
                    "resources",
                    "app",
                    "node_modules.asar.unpacked",
                    "node-pty",
                    "build",
                    "Release",
                    "spawn-helper",
                )

                if not os.path.exists(patched_spawn_helper):
                    logger.error("local vscode does not have a patched spawn-helper")
                    exit(1)

                subprocess.run(
                    [
                        "ln",
                        "-sfT",
                        patched_spawn_helper,
                        file_path,
                    ]
                )

    extensions_path = os.path.join(path, "extensions")

    for root, _subdirs, files in os.walk(extensions_path):
        for file in files:
            file_path = os.path.join(root, file)
            if is_elf(file_path):
                logger.warning(f"Patching {file_path}")
                subprocess.run(
                    [
                        patchelf,
                        file_path,
                        "--set-interpreter",
                        interpreter,
                        "--add-rpath",
                        rpath,
                    ]
                )
