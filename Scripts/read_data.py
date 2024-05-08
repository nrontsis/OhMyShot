from io import StringIO
import glob
import os
from pathlib import Path

import numpy as np
import pandas as pd
import typing as t


def to_series(time_series_string: str) -> pd.Series:
    times_str, values_str = time_series_string[:-3].split("times: ")[1].split(", values: ")
    if times_str in ["[0.0]", "[]"]:
        return pd.Series([], [], dtype="float64")

    times = np.loadtxt(StringIO(times_str[1:-1]), delimiter=',')
    values = np.loadtxt(StringIO(values_str[1:-1]), delimiter=',')
    return pd.Series(values, index=times)


def print_commands(messages_strings: t.List[str]) -> None:
    # Reversed is simply out of convenience: to show most recent shot last.
    for i, messages_string in reversed(list(enumerate(messages_strings))):
        print("\n\n\n#####################")
        print("SHOT ", i)
        print("#####################")
        message_list = messages_string.split("[")[1].split("]")[0].split(", ")
        for message in message_list:
           if "cmd" in message:
                print(message)


if __name__ == "__main__":
    files = list(glob.glob(str(Path.home()) + "/Downloads/text*.txt"))
    files.sort(key=lambda x: -os.path.getmtime(x))
    print("Enter the number of the file you want to open: [Default: latest added (0)]")
    for idx, file in enumerate(files):
        print(f"{idx}: {file}")
    try:
        file_idx = int(input())
    except ValueError:
        file_idx = 0
    print("Selected file:", files[file_idx])
    lines = open(files[file_idx], 'r').readlines()
    messages = [line for line in lines if line.startswith('Coffee machine')]
    weight_strings = [line for line in lines if line.startswith('Time series')]
    print_commands(messages)
    weight_series = [to_series(s) for s in weight_strings[:1]]
    weight_series[0].rename("weight [g]").to_csv("data.csv", index_label="Time [s]")
    """
    import matplotlib.pyplot as plt
    weight_series[0].plot()
    pyplot_series[0].show()
    """


