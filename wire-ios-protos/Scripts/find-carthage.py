#!/usr/bin/env python
#
# Finds the folder where Carthage checkouts are. This could be a subfolder of the current folder, or 
# a parent folder of the current folder
#

import os
import sys

def find_in_path(path):
    components = path.split(os.sep)
    for i, j in enumerate(components):
        if j == "Carthage":
            return os.path.join("/",*components[:i+1])
    return None
    
def find_in_subfolder(path):
    cartfolder = os.path.join(path, "Carthage")
    if os.path.isdir(cartfolder):
        return cartfolder
    return None

if __name__ == "__main__":
    cwd = os.path.normpath(os.getcwd())
    paths = [find_in_path(cwd), find_in_subfolder(cwd)]
    for found_path in [x for x in paths if x != None]:
        print(found_path)
        sys.exit(0)
    
    print("No Carthage folder found", file=sys.stderr)
    sys.exit(1)
    
