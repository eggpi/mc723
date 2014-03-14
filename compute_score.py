#!/usr/bin/env python

import sys
import glob
import os.path
import pprint

def compute_score(results_dir):
    averages = {}
    result_files = os.path.join(results_dir, "*")
    for rf in glob.glob(result_files):
        timings = []
        benchmark = os.path.basename(rf)

        with open(rf, "r") as f:
            for line in f:
                line = line.strip()
                minutes, seconds = line.split("m")
                seconds = seconds[:-1]

                seconds = 60 * float(minutes) + float(seconds)
                timings.append(seconds)

        averages[benchmark] = sum(timings) / len(timings)

    score = sum(averages.values())
    pprint.pprint(averages)
    print "SCORE: %.4f" % score

if __name__ == '__main__':
    compute_score(sys.argv[1])
