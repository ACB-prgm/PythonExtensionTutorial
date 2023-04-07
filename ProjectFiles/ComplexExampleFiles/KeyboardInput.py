import keyboard
import socket
import json
import os


opened_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
UDP_IP = "127.0.0.1"
UDP_PORT = 4243
inputs = [
    "ctrl"
]


def main():
    pid = os.getppid()
    put_packet(["PIDs", pid])

    for input_ in inputs:
        keyboard.add_hotkey(input_, lambda : on_input(input_)) # only need to be added once, Keyboard caches

    keyboard.wait()


def on_input(input):
    input = ["KEY_INPUT", input]
    put_packet(input)


def put_packet(packet):
    byte_message = bytes(json.dumps(packet), "utf-8")
    opened_socket.sendto(byte_message, (UDP_IP, UDP_PORT))


if __name__ == "__main__":
    main()


# sudo python /Users/aaronbastian/Documents/PythonCode/KeyboardInput/KeyboardInputTest.py
# DOCS: https://github.com/boppreh/keyboard#keyboard.KEY_DOWN