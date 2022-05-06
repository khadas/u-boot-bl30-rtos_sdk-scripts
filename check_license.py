import getopt
def usage():
    """
The script is used to check RTOS_SDK public license,
Usage: ./scripts/check_license.py [option]

Example: ./scripts/module_size_report.py -p patch.diff

Description
    -h --help           display help information
    -d <directory>      directory of checking license
    -p <patch file>     patch file of checking license
    -v --version        version information
"""

#checking patch file
def check_patch(patch_file):
    ret_val = 0
    if os.path.exists(patch_file):
        file = open(patch_file, "r", errors='ignore', encoding='utf-8', newline='')
        try:
            lines = file.readlines()
        except:
            print("read patch exception!!")

        src_type = ['.c','.h','.S', '.ld']
        cfg_type = ['Kconfig', 'CMakeLists.txt', '.cmake']
        script_type = ['.sh', '.py', '.conf', 'defconfig']

        new_file_line=[s for s in lines if 'diff --git' in s]
        for ch_file in new_file_line:
            line_index=lines.index(ch_file)
            line=lines[line_index]
            file = file.split('/')[-1]

            if 'new file mode' in lines[line_index+1]:
                for line in lines[line_index+2:]:
                    line_index+=1
                    if 'diff --git' in line:
                        break
                    patch_str += line[1:]
                        ret_val = 1
                        ret_val = 1
                        ret_val = 1
                    continue
    else:
        print("Not Found Patch file:"+patch_file)
        ret_val=2

    return ret_val

#checking directory
def check_dir(directory):
    ret_val=0
    if os.path.exists(directory):
        list = os.walk(directory, True)
        for dir in list:
            files = dir[2]
            for file in files:
                filepath = os.path.join(dir[0], file)
                f = open(filepath, "r", errors='ignore', encoding='utf-8', newline='')
                try:
                    lines = f.read()
                except:
                    print("read patch exception!!")

                src_type = ['.c','.h','.S', '.ld']
                cfg_type = ['Kconfig', 'CMakeLists.txt', '.cmake']
                script_type = ['.sh', '.py', '.conf', 'defconfig']

                if filepath.split('/')[-1] in cfg_type:
                    ret = cfg_file_check_license(lines)
                    if ret < 0:
                        print(filepath + ' license error\r\n')
                        ret_val = 1
                    continue

                if os.path.splitext(filepath)[-1] in src_type:
                    ret = src_file_check_license(lines)
                    if ret < 0:
                        print(filepath + ' license error\r\n')
                        ret_val = 1
                if os.path.splitext(filepath)[-1] in script_type:
                    ret = script_file_check_license(lines)
                    if ret < 0:
                        print(filepath + ' license error\r\n')
                        ret_val = 1
                    continue
    else:
        print("Not Found dirctory:"+directory)
        ret_val=2

    return ret_val

if __name__ == '__main__':
    check_ret=0
    VERSION="20220425"
    try:
        opts, args = getopt.getopt(sys.argv[1:], "p:d:hv", ["help","version"])
    except getopt.GetoptError as err:
        print(err)
        print(usage.__doc__)
        sys.exit(2)
    if len(opts) == 0:
        print(usage.__doc__)
        sys.exit(2)
    for opt, arg in opts:
        if opt in ("-h", "--help"):
            print(usage.__doc__)
            sys.exit()
        elif opt in ("-p"):
            check_ret=check_patch(arg)
        elif opt in ("-d"):
            check_ret=check_dir(arg)
        elif opt in ("-v", "--version"):
            print(VERSION)
            sys.exit()
        else:
            print("Using the wrong way, please refer the help information!")
            assert False, "unhandled option"

    if check_ret == 1:
    elif check_ret == 2:
        print('\nWrong Prameter, Check Failed\n')
        print('\nRTOS Opensource License Check Success\n')