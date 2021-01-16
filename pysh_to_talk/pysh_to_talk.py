#!/usr/bin/env python3

import subprocess

from pynput import keyboard

KEY = keyboard.Key.scroll_lock
SOURCE = '@DEFAULT_SOURCE@'


class PushToTalk():
    def __init__(self, source, key):
        # Mute microphone as default state
        self.muted = True
        self.pactl_command = 'pactl set-source-mute {} '.format(source)

        self.execute_command(self.pactl_command + '1')

        with keyboard.Listener(
                on_press=self.on_press,
                on_release=self.on_release
        ) as listener:
            listener.join()

    def execute_command(self, command):
        subprocess.run(
            command.split(' '),
            check=True
        )

    def on_press(self, key):
        if self.muted and key == KEY:
            self.execute_command(self.pactl_command + '0')
            self.muted = False

    def on_release(self, key):
        if not key == KEY:
            return

        self.execute_command(self.pactl_command + '1')
        self.muted = True


if __name__ == '__main__':
    PushToTalk(SOURCE, KEY)
