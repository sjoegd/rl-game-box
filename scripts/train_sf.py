import argparse
#import os
#import pathlib

# TODO: finish

parser = argparse.ArgumentParser(allow_abbrev=False)

parser.add_argument(
    "--game",
    default=None,
    type=str
)

parser.add_argument(
    "--build_path",
    default=None,
    type=str
)

parser.add_argument(
    "--experiment_name",
    default=None,
    type=str
)

parser.add_argument(
    "--timesteps",
    default="1_000_000",
    type=str
)

parser.add_argument(
    "--inference",
    default="False",
    type=str
)

parser.add_argument(
    "--viz",
    default="False",
    type=str
)

parser.add_argument(
    "--speedup",
    default="1",
    type=str
)

args, extra = parser.parse_known_args()






