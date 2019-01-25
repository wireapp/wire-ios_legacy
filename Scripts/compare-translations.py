#!/usr/bin/env python
# -*- coding: UTF-8 -*-
#
# Wire
# Copyright (C) 2018 Wire Swiss GmbH
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see http://www.gnu.org/licenses/.
#

from __future__ import print_function
import argparse
import os
import sys
import re
import codecs
import re
import shutil

MAX_ERRORS = 20
VALUE_REGEX = re.compile(r"^\"([^=]+)\"\s*=\s*\"(.*)\";$")
LANGUAGE_FOLDER_EXT = ".lproj"
STRINGS_FILE = "Localizable.strings"
TEMPLATE_REGEX = re.compile(u"(%(?:(?:[0-9]$)?(?:@|[a-z])))")
BASE_LANGUAGE = "Base" + LANGUAGE_FOLDER_EXT
FILES_TO_COPY = set([
    "Localizable.stringsdict",
    "Localizable.strings",
    "InfoPlist.strings"
])

def copy_language_files(src, dst):
    if not os.path.exists(dst):
        os.makedirs(dst)
    for f in FILES_TO_COPY:
        s = os.path.join(src, f)
        d = os.path.join(dst, f)
        if os.path.isfile(s):
            shutil.copy2(s, d)

def die(*args):
    '''Print error and exit'''
    print(u"ERROR:", end=" ", file=sys.stderr)
    print(*args, file=sys.stderr)
    exit(1)

def main(original_folder, modified_folder, ignore_missing, destination_folder):
    os.path.isdir(original_folder) or die(original_folder + " is not a folder")
    os.path.isdir(modified_folder) or die(modified_folder + " is not a folder")
    original_languages = language_folders_in_folder(original_folder)
    modified_languages = language_folders_in_folder(modified_folder)

    # Check if any language is missing
    check_missing_languages(original_languages, modified_languages, ignore_missing)

    # Verify
    for language in original_languages:
        if language in modified_languages: 
            check_language_files(language, original_folder, modified_folder)
        
    # Copy
    if destination_folder:
        copy_language(BASE_LANGUAGE, modified_folder, destination_folder)
        for language in original_languages:
            copy_language(language, modified_folder, destination_folder)

def check_missing_languages(original_languages, modified_languages, ignore_missing):
    '''Check that the two lists contain the same languages'''
    lang_original = set(original_languages)
    lang_modified = set(modified_languages)
    
    BASE_LANGUAGE in lang_original or die("No", BASE_LANGUAGE, "in original folder, is it a resource folder?")
    BASE_LANGUAGE in lang_modified or die("No", BASE_LANGUAGE, "in modified folder, is it a resource folder?")

    missing_languages = lang_original - lang_modified
    if ignore_missing and len(missing_languages) > 0:
        print("Ignoring missing languages:", ", ".join(missing_languages))
    else:
        len(missing_languages) == 0 or die("Missing languages: ", ", ".join(missing_languages))

    extra_languages = lang_modified - lang_original
    len(extra_languages) == 0 or die("Extra languages not present in the original: ", ", ".join(extra_languages))

def copy_language(language, source_folder, destination_folder):
    '''Copy language from modified to original folder. If a language is missing, it takes the base language in the destination folder'''
    source = os.path.join(source_folder, language)
    destination = os.path.join(destination_folder, language)
    base = os.path.join(destination_folder, BASE_LANGUAGE)
    
    if os.path.isdir(source):
        print("Copying {}".format(language))
    else:
        print("Copying base language for {}".format(language))
    copy_language_files(source if os.path.isdir(source) else base, destination)

def check_language_files(language, original_folder, modified_folder):
    '''Check that the language file has the same entry in both folders'''
    original_strings_file = os.path.join(original_folder, language, STRINGS_FILE)
    modified_strings_file = os.path.join(modified_folder, language, STRINGS_FILE)
    os.path.isfile(original_strings_file) or die("Missing file in original folder: ", original_strings_file)
    os.path.isfile(modified_strings_file) or die("Missing file in modified folder: ", modified_strings_file)
    print("Checking", modified_strings_file, "...")

    try:
        original_strings = load_file_to_dict(original_strings_file)
    except Exception as e:
        die(u"Failed to parse file:", original_strings_file, e.message)
    try:
        modified_strings = load_file_to_dict(modified_strings_file)
    except Exception as e:
        die(u"Failed to parse file:", modified_strings_file, e.message)

    original_keys = set(original_strings.keys())
    modified_keys = set(modified_strings.keys())

    if original_keys != modified_keys:
        missing = original_keys - modified_keys
        len(missing) == 0 or die("Missing entries in modified file", modified_strings_file, ":", ", ".join(missing))
        extra = modified_keys - original_keys
        len(extra) == 0 or die("Modified entries in", modified_strings_file, "are not present in the original file:", ", ".join(extra))

    errors = []

    for key in original_keys:
        original = original_strings[key]
        modified = modified_strings[key]
        original_match = TEMPLATE_REGEX.search(original)
        modified_match = TEMPLATE_REGEX.search(modified)
        original_matches = [] if original_match is None else original_match.groups()
        modified_matches = [] if modified_match is None else modified_match.groups()
        if original_matches != modified_matches:
            errors.append(u"Mismatch for key '{}' in '{}':\noriginal: {}\nmodified: {}".format(key, language, original, modified))
        
    if len(errors) > 0:
        was_longer = len(errors) > MAX_ERRORS
        if was_longer:
            errors = errors[:MAX_ERRORS]
            errors.append("... showing only the first {} errors".format(MAX_ERRORS)) 
        die("\n".join(errors))

def language_folders_in_folder(folder):
    '''Find all language folders inside the given folder'''
    return [entry for entry in os.listdir(folder) if os.path.isdir(os.path.join(folder, entry)) and entry.endswith(LANGUAGE_FOLDER_EXT)]

def _comment_remover(text):
    '''Remove `Localization.strings`-style comments from text'''
    multiline_pattern = re.compile(r'/\*.*?\*/', re.DOTALL | re.MULTILINE)
    text = multiline_pattern.sub(" ", text)

    comment_with_delimiter = "{q}(?:\\.|[^\\{q}])*{q}"
    quotes = comment_with_delimiter.format(q="\"")
    single_quote = comment_with_delimiter.format(q="'")
    single_line_pattern = re.compile(
        "//.*?$|{}|{}".format(quotes, single_quote),
        re.MULTILINE
    )
    return single_line_pattern.sub(lambda x: " " if x.group(0).startswith("/") else x.group(0), text)

def load_file_to_dict(path):
    '''Load a strings file to a dictionary'''

    with codecs.open(path, 'r', encoding="utf-8") as source:
        content = source.read()

    lines = [x.strip() for x in _comment_remover(content).split("\n") if x.strip() != ""]

    values = {}
    for line in lines:
        match = VALUE_REGEX.match(line)
        if match:
            values[match.group(1)] = match.group(2)
        else:
            raise Exception(u"Can not parse line:\n\t{}".format(line))

    return values

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Checks that translations in XCode-format resources folders are in sync")
    parser.add_argument("original_folder", help="Resource folder with the original strings")
    parser.add_argument("modified_folder", help="Resource folder with the translated strings")
    parser.add_argument("--copy-to", help="Copy languages to this destination folder", dest="copy_to")
    parser.add_argument("--ignore-missing", action="store_true", dest="ignore_missing", help="Ignore missing languages")
    args = parser.parse_args()
    main(args.original_folder, args.modified_folder, args.ignore_missing, args.copy_to)
