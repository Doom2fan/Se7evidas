#!python3

#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
#  MA 02110-1301, USA.
#

from __future__ import print_function

import os
import subprocess
import zipfile
import sys
import shutil

from tempfile import mkdtemp
from fnmatch import fnmatch

SRC_DIR = "PK3 Source"
DIST_FNAME = "Se7evidas"
IGNORED_FILES = [
    "*.db",
    "*.dbs",
    "*.bak*",
    "*.backup*",
    "*.tmp*"
]

def query_yes_no (question, default = "no"):
    """Ask a yes/no question via raw_input () and return their answer.

    "question" is a string that is presented to the user.
    "default" is the presumed answer if the user just hits <Enter>.
        It must be "yes" (the default), "no" or None (meaning
        an answer is required of the user).

    The "answer" return value is True for "yes" or False for "no".
    """
    valid = { "yes": True, "y": True, "ye": True,
              "no": False, "n": False }
    if (default is None):
        prompt = " [y/n] "
    elif (default == "yes"):
        prompt = " [Y/n] "
    elif (default == "no"):
        prompt = " [y/N] "
    else:
        raise ValueError ("Invalid default answer: '%s'" % default)

    while (True):
        sys.stdout.write (question + prompt)
        choice = getinput ().lower ()
        if (default is not None and choice == ''):
            return valid [default]
        elif (choice in valid):
            return valid [choice]
        else:
            sys.stdout.write ("Please respond with 'yes' or 'no' "
                              "(or 'y' or 'n').\n")

def getinput (header = ""):
    try:
        raw_input
    except NameError:
        return input (header)
    else:
        return raw_input (header)

def getchoice (choices, header = None):
    if (header != None):
        print (40 * '-')
        print (header)
        print (40 * '-')
        print ("")

    for tup in choices:
        print ("{num}) {text}".format (num = tup [0], text = tup [1]))

    choice = getinput ("Enter your choice: ")

    for tup in choices:
        if (choice == tup [0]):
            return choice

    return None

def getoutdir ():
    try:
        return getinput ();
    except:
        return None

def compress_folder (destination, src, compression, ignoredFiles = [], quiet = False):
    filelist = []
    for path, dirs, files in os.walk (src):
        for file in files:
            name = os.path.relpath (os.path.join (path, file), src)

            for pattern in ignoredFiles:
                if (fnmatch (file, pattern)):
                    continue

            filelist.append ((os.path.join (path, file), name,))

    with zipfile.ZipFile (destination, "w", compression) as distzip:
        current = 1
        for file in filelist:
            if (not quiet):
                print ("[{percent:>3d}%] Adding {filename}".format (percent = int (current * 100 / len (filelist)), filename = file [1]))

            distzip.write (*file)
            current += 1

def get_file_out_path (defName, defExt):
    while (True):
        print ("Specify the output directory and/or filename: ", end = "")
        outDir = getoutdir ()

        splitPath = os.path.split (outDir)
        if (splitPath [0] == "" and splitPath [1] == ""):
            destination = defName + defExt
        elif (splitPath [0] == ""):
            destination = splitPath [1]
        elif (splitPath [1] == ""):
            destination = os.path.join (splitPath [0], defName + defExt)
        else:
            destination = outDir

        if (os.path.exists (destination)):
            print ("")

            if not query_yes_no ("File \"{dest}\" already exists. Overwrite?".format (dest = destination), None):
                print ("Press return to exit...")
                getinput ()
                return None

            break
        else:
            try:
                with open (destination, 'x') as tempfile: # OSError if file exists or is invalid
                    break
            except OSError:
                print ("Invalid path")

    return destination

def get_compression_method (header, bzipAllowed = False):
    while (True):
        choices = [
            ("1", "Store"),
            ("2", "Deflate"),
            ("3", "LZMA"),
        ]
        if (bzipAllowed):
            choices.append (("4", "BZip"))

        choice = getchoice (choices, header)

        if (choice is not None):
            break
        else:
            print ("Invalid choice")

        print ("")

    if (choice == "1"):
        return zipfile.ZIP_STORED
    elif (choice == "2"):
        return zipfile.ZIP_DEFLATED
    elif (choice == "3"):
        return zipfile.ZIP_LZMA
    elif (bzipAllowed and choice == "4"):
        return zipfile.ZIP_BZIP2

def compile_pk3 (outDir = None, compression = None):
    if (outDir is not None):
        destination = os.path.join (outDir, DIST_FNAME + ".pk3")

        if (os.path.exists (destination)):
            return False
    else:
        destination = get_file_out_path (DIST_FNAME, ".pk3")

        if (destination is None):
            return False

    baseDir = os.path.dirname (destination)
    if (baseDir != "" and not os.path.exists (baseDir)):
        os.makedirs (baseDir)

    print ("")
    if (compression is None):
        compression = get_compression_method ("Select the PK3's compression type:")

    print ("-- Compressing {filename} --".format (filename = destination))
    compress_folder (destination, SRC_DIR, compression, IGNORED_FILES, False)

    return True

def compile_release (outDir = None, relComp = None):
    additionalFiles = [
        ("Se7evidas-README.txt",),
        ("Se7evidas-TODO.txt",),
        ("LICENSE", "Se7evidas-Assets license.txt"),
    ]

    if (outDir is not None):
        destination = os.path.join (outDir, DIST_FNAME + ".zip")

        if (os.path.exists (destination)):
            return False
    else:
        destination = get_file_out_path (DIST_FNAME, ".zip")

        if (destination is None):
            return False

    baseDir = os.path.dirname (destination)
    if (baseDir != "" and not os.path.exists (baseDir)):
        os.makedirs (baseDir)

    tmpDir = mkdtemp ()

    try:
        compile_pk3 (tmpDir)
        for tup in additionalFiles:
            if (len (tup) == 2):
                dstName = tup [1]
            else:
                dstName = tup [0]
            shutil.copy2 (tup [0], os.path.join (tmpDir, dstName))

        print ("")
        if (relComp is None):
            relComp = get_compression_method ("Select the zip file's compression type:", True)

        print ("-- Compressing {filename} --".format (filename = destination))
        compress_folder (destination, tmpDir, relComp, IGNORED_FILES, False)
    finally:
        shutil.rmtree (tmpDir, True)

    return True

if (__name__ == "__main__"):
    while (True):
        header = "Select what to compile:"
        choices = [
            ("1", "PK3"),
            ("2", "Release"),
            ("0", "Exit"),
        ]
        choice = getchoice (choices, header)

        if (choice is not None):
            break
        else:
            print ("Invalid choice")

        print ("")

    if (choice == "1"):
        compile_pk3 ()
    elif (choice == "2"):
        compile_release ()
##
##    makepkg ()
##    maketxt ()*/
##
##    print("-- Finished --")
