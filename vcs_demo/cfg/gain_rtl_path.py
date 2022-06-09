#! /usr/bin/python

import os
import time
import sys
import re
import argparse
from functools import wraps

def input_wrap():
    global lst
    global all_lst
    global sys_log
    global re_cmp
    parser = argparse.ArgumentParser()
    parser.add_argument("-f", "--file_list", help="list file path", default="")
    parser.add_argument("-l", "--all_list", help="list file path", default="")
    parser.add_argument("-r", help="re compile", action="store_true")
    args = parser.parse_args()
    lst = args.file_list
    all_lst = args.all_list
    re_cmp = args.r
    (filename,extension) = os.path.splitext(lst)
    sys_log = filename + "_sys_all_file.lst"


def wrap_rm_add_file(f):
    @wraps(f)
    def rm_add_file(*args, **kwargs):
        before_file = os.listdir(os.getcwd())
        print(f.__name__ + " was called")
        file_list = f(*args, **kwargs)
        for file in os.listdir(os.getcwd()):
            if file not in before_file:
                print("rm %s" % file)
                os.system("rm -rf %s" % file)
        return file_list
    return rm_add_file

def wrap_catch_except(f):
    def wrapper(*args, **kwargs):
        try:
            return f(*args, **kwargs)
        except Exception, e:
            print("error %s" % e)
    return wrapper

def replace_env_var(path):
    def get_env(match):
        return os.getenv(match.group(1))
    path = re.sub(r"\$(\w+)", get_env, path)
    return path

def replace_relative_path(base, offset=""):
    if offset != "":
        path = os.path.join(base, offset)
    else:
        path = base
    path = re.sub(r"\/.\/\/", "//", path) # /path/./aaa -> /path//a
    path = re.sub(r"\/+", "/", path) #/path///aa//b -> /path/a/b
    while re.search(r"\w+\/\.\.\/", path):
        path = re.sub(r"\w+\/\.\.\/", "",path) #/path/aa/../b -> /path/b
    return path

def process_list(lst):
    file_list = []
    lst = lst.strip()
    lst = replace_relative_path(replace_env_var(lst))
    file_list.append(lst)
    (filepath, filename) = os.path.split(lst)
    with open (lst, "r") as handle:
        for line in handle:
            line = re.sub(r"\/\/.*", "", line)
            if line != "":
                re0 = re.match(r"\+incdir\+(.*)", line)
                re1 = re.match(r"\-f\s+(.*)", line)
                re2 = re.match(r"-v", line)
                re3 = re.match(r"-y", line)
                if re0:
                    path = replace_relative_path(replace_env_var(re0.group(1)))
                    file_list.append(path)
                elif re1:
                    path = replace_relative_path(replace_env_var(re1.group(1)))
                    file_list.extend(process_list(path))
                elif not re2 and not re3:
                    path = line.strip()
                    path = replace_relative_path(replace_env_var(path))
                    file_list.append(path)
    return file_list


@wrap_catch_except
@wrap_rm_add_file
def vcs_run_file():
    file_list = []
    global sys_log
    global all_lst
    global re_cmp
    
    cmd = "vcs -f tb.f -l %s +libext+.sv+.v +v2k -sverilog -ntb_opts uvm-1.2 -timescale=1ns/1ps -unit_timescale=1ns/1ps" % sys_log
    os.system(cmd) if re_cmp == True or not os.path.exists(sys_log) else ""
    print("compile yes")
    
    with open(sys_log) as f:
        for line in f.readlines():
            if re.search(r"file '(.*)'", line):
                file_list.append(re.search(r"file '(.*)'", line).group(1))
    return list(set(file_list))

def main():
    global all_lst
    global re_cmp
    
    input_wrap()
    
    if all_lst == "":
        file_list = vcs_run_file()
        if not os.path.exists(sys_log):
            with open(sys_log, "w") as f:
                for line in file_list:
                    f.write(line+"\n")

if __name__ == '__main__':
    main()
