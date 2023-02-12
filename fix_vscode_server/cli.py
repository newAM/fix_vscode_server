from fix_vscode_server import fix_vscode_server
import argparse
import logging
import os


def main():
    handler = logging.StreamHandler()
    handler.setLevel(logging.DEBUG)
    formatter = logging.Formatter("{message}", style="{")
    handler.setFormatter(formatter)

    root_logger = logging.getLogger()
    root_logger.setLevel(logging.DEBUG)
    root_logger.addHandler(handler)

    parser = argparse.ArgumentParser()
    parser.add_argument("--patchelf")
    parser.add_argument("--interpreter")
    parser.add_argument("--rpath")
    parser.add_argument("--vscode")
    args = parser.parse_args()

    vscode_server_path = os.path.join(os.path.expanduser("~"), ".vscode-server")
    fix_vscode_server(
        vscode_server_path,
        patchelf=args.patchelf,
        interpreter=args.interpreter,
        rpath=args.rpath,
        vscode=args.vscode,
    )
