# Moirai2

## Description

MOIRAI2 is a simple scientific workflow system written in perl to process multiple commands sequentially, keep logs/history of commands, and construct a meta database of files and values (notated with [triples](https://en.wikipedia.org/wiki/Semantic_triple)) with simple to use bash like notation. 

For example:

> perl moirai2.pl exec ls -lt

This will simply execute 'ls -lt' command and store stdout output, time of executions, and command line information in [a log file](example/log/e20220424224043Mbqj.txt) under .moirai2/log directory.

> perl moirai2.pl -o 'example->file->$output' exec 'echo hello world > $output'

This will execute a command 'echo hello world > $output' and create an [output file](example/text/output) with a content "hello world" with a [log file](example/log/e20220424224158meiw.txt) with execution information.  It will also record a simple triple (subject=example, predicate=file, and object=filepath to output) in text based [database file](example/db/file.txt) (predicate is recorded in a basename of a file).

'echo hello world > $output' is quoted with a single quote (') because a command contains redirect '>' and '$'.  If a command line is not quoted, redirect to a file will be handled by the unix system and not by moirai2 system.  A single quote (') is used instead of double quote ("), because a variable quoted with double quote (") will be replaced by the value by unix system before passing to moirai2.  Single quote will not replace by the value, so single quote is recommended in this case.  If you want to use double quote ("), you can escape $'' with '\' like "echo hello world > \$output"

> perl moirai2.pl -i 'example->file->$input' -o '$input->count->$count' exec 'wc -l $input > $count'

Using an output file with content 'hello world' from the previous execution, moirai2 will execute a word count (wc) command and store its result in $output file.   An [output file](example/text/count), a [log file](example/log/e20220424224235CQWg.txt) and a metadata [triple file](example/db/count.txt) (subject=filepath to hello world text file, predicate=count, object=1) will be created.  Moirai2 checks for output triple before executing a command line.  If an output triple is found (meaning it's been executed before), wc process will not be executed.

> perl moirai2.pl -i '$input->count->$count' -o '$input->charcount->$count' exec 'wc -c $input > $count'

Chain of commands can be connected by linking in/out triples like example above.  This is how moiri2.pl handles a scientific workflow.  Processes are loosely linked by triples which gives flexibility to a workflow, since a triple can be written by user directly, or through web interface, or through moirai computation.

## Structure
```
moirai2/
├── Dockerfile - a docker file of moirai2.
├── README.md - This readme file
├── command/ - a collection of command line files.
├── css/ - stylesheet used by jquery columns.
├── docker-compose.yml - docker-compose to run moirai2 web site.
├── example/ - a collection of example files
├── flask/ - files used for running web server through docker-compose
├── images/ - images used by jquery columns.
├── js/ - Javascript used for MOIRAI2 manipulation through a browser.
│   ├── ah3q/ - my javascripts fro moirai2
│   ├── jquery/ - jquery (https://visjs.org) scripts
│   └── vis/ - vis (https://visjs.org) scripts for network graphs
├── moirai2.php - Used for MOIRAI2 manipulation through a browser interface.
├── moirai2.pl - Assign and process MOIRAI2 commands.
├── openstack.pl - A collection of commands to run Openstack for moirai2.
└── rdf.pl - Script to handle a text-based triple (sub,pre,obj) database.
```

## Install

Use git command to clone project to your computer.
git is preinstalled in MacOS.
For Linux, you can install through 'apt-get'?
You can check the git by checking its version.

```
git --version
```

To install moirai2 to a directory named "project".

```shell
$ git clone https://github.com/moirai2/moirai2.git project
```

## Scripts

### moirai2.pl

>Commands:
>             build  Build a command json from command lines and script files
>       clear/clean  Clean all command log and history by removing .moirai2 directory
>           command  Execute user specified command from STDIN
>            daemon  Checks and runs the submitted and automated scripts/jobs
>              exec  Execute user specified command from ARGUMENTS
>              html  Output HTML files of command/logs/database
>           history  List up executed commands
>                ls  Create triples from directories/files and show or store them in triple database
>               log  Print out logs information of processes
>              open  Open .moirai2 directory (for Mac only)
>         newdaemon  Setup a new daemon specified server
>         openstack  Use openstack.pl to create new instance to process jobs
>          sortsubs  For reorganizing this script(test commands)
>            submit  Submit job with command URL and parameters specified in STDIN
>              test  For development purpose (test commands)

#### Work directory
With each execution of process, a work directory is created under .moirai2/ with 'YYYYMMDDhhmmssXXXX' format where YYYY is year, MM is month, DD, is day, hh is hour, mm is minute, ss is second, and XXXX is a random character (for example, a directory path will be '.moirai2/e20220424202838b86T/').  'YYYYMMDDhhmmssXXXX' is also used as an execid of the process too.

These files will be created under work directory:
- log.txt - a file to keep command, input, output, and time information
- run.sh - a bash file used to run command
- status.txt - keep current status and timestamp
- stderr.txt - STDERR output from running command
- stdout.txt - STDOUT output from running command

These files will be deleted after execution and all the results will be summarized into one log file.

#### Summary File
A summary file is divided into these section:
- execid - a command URL, input and output parameters, and status.
- time - registered, start, end, and completed datetime
- stdout - STDOUT of command if exists
- stderr - STDERR of command if exists
- bash - actual command lines used for processing

- If command is successful, a summary file 'YYYYMMDDhhmmssXXXX.txt' will be placed under '.moiri2/log/YYYYMMDD/' directory.
- If error occurs, a summary file 'YYYYMMDDhhmmssXXXX.txt' will be placed under '.moirai2/error/' directory.

A summary file can be viewed from a command line.

>perl moirai2.pl history EXECID

List of execids can be listed with this command.

>perl moirai2.pl history 

#### Temporary directory

A temporary directory (.moirai2/YYYYMMDDhhmmssXXXX/tmp/) is created under a work directory (.moirai2/YYYYMMDDhhmmssXXXX/).  During process, a temporary directory (.moirai2/YYYYMMDDhhmmssXXXX/tmp/) will be symbolic linked from /tmp/YYYYMMDDhhmmssXXXX.  After completion, a symbolic link will be replaced by the actual directory (mv /tmp/YYYYMMDDhhmmssXXXX .moirai2/YYYYMMDDhhmmssXXXX/tmp/).  By writing result to a temporary directory, I/O traffic will be reduced by using a local directory of nodes.

To use this temporary directory, use '$tmpdir' variable.

> perl moirai2.pl exec 'ls -lt > $tmpdir/output.txt'

When output variable exists in a command line, moirai2 automatically creates a temporary file path.

> perl moirai2.pl -o output exec 'ls -lt > $output'

output=$tmpdir/output will be assigned at the beginning of a bash file.

> perl moirai2.pl -o output exec 'ls -lt > $output;' output=output.txt

By specifying output file path, path will be replaced after the computation (See [log file](example/log/e20220426105225k0Wr.txt).

> output=$tmpdir/output
> ls -lt > $output
> mv $output output.txt

#### Command Mode
#### Input/Output Triples
#### Running multiple command lines at once
#### Multiple inputs
#### Multiple outputs
#### Running with Singularity docker
#### Running command on remote server
#### scp used to upload input and download output

### rdf.pl
#### Triple database
#### Triple text files grouped by predicates
#### Directory predicate
#### Multiple queries notation
#### Accessing triples on the web http
#### Editing by hands

### Web interface
#### moirai2.php
#### moirai2.js
####  flask docker-compose

### openstack.pl
#### Setup

### Daemon
>perl moirai2.pl daemon
Moirai2 can run in daemon mode where program checks for jobs in background and process when found.  Jobs can be assigned in two mode:
- crontab  moirai2 checks for updates in triple database and process jobs when applicable changes are found.  This is used for an automation of data production.
- submit  moirai2 checks for a text file under .moirai2/ctrl/submit directory.  A text file contains which command json to use and its parameters.  This is a gateway for a web interface.

#### crontab
>perl moirai2.pl daemon crontab

By placing a bash file with input triple (root->input->$input) information in .moirai2/crontab/ directory, moirai2 periodically checks for new entry in predicate=input and process if found.

> #$-i root->input->$input
> #$-o $input->count->$count
> output=`wc -l < $input`

Let's say we a file example.txt with just "Hello World", for example.
If a new triple 'root->input->example.txt' is added to the database (equivalent of 'root  example.txt' line is added to input.txt), moirai2.pl execute 'output=`wc -l < example.txt`' and stores the result in triple database 'example.txt->count->1' (equivalent of 'example.txt 1' in count.txt).

#### submit
>perl moirai2.pl daemon submit

By placing a text file like example bellow under .moirai2/ctrl/submit/ directory, moirai2 will submit a new job using a command json file "example.json" and input parameter "example.txt".

> url   example.json
> input example.txt

>perl moirai2.pl daemon process

#### Jobs Across Internet

Processing of jobs are controlled by the existance of files under .moriai2/ctrl/job/ directory.  When a job is processed, a file will be transferred from .moirai2/ctrl/job/ to .moirai2/ctrl/process/ directory.  It is possible to share a .moriai2/ctrl/job/ directory across internet by specifying a username, server and directory with -j option like example bellow.  This will look for a file under  .moirai2/ctrl/job/ at 192.168.1.1 and if slot is available, a command file, input files, and parameters will be copied to the remote server and will be processed.  After the computation, output and logs will be copied back to the main server.

##### One server and multiple nodes
Main server takes care of crontab and submit, but no process.  Moirai directory will be created /home/ah3q/main/.moirai2/.  Nodes will look for a new job under /home/ah3q/main/.moirai2/ctrl/job at 192.168.1.1 server.

> # main server
> cd /home/ah3q/main
> perl moirai2.pl daemon crontab submit
> # Log in to node server1 (192.168.1.2)
> perl moirai2.pl -j ah3q@192.168.1.1:main daemon processs
> # Log in to node server2 (192.168.1.3)
> perl moirai2.pl -j ah3q@192.168.1.1:main daemon processs
> # Log in to node server3 (192.168.1.4)
> perl moirai2.pl -j ah3q@192.168.1.1:main daemon processs
> # Log in to node server4 (192.168.1.5)
> perl moirai2.pl -j ah3q@192.168.1.1:main daemon processs

It's possible to deploy from main server in one bash script using -b option.  Make sure SSH keys are properly configured.

> cd /home/ah3q/main
> perl moirai2.pl daemon crontab submit
> perl moirai2.pl -b ah3q@192.168.1.2 -j ah3q@192.168.1.1:main daemon processs
> perl moirai2.pl -b ah3q@192.168.1.3 -j ah3q@192.168.1.1:main daemon processs
> perl moirai2.pl -b ah3q@192.168.1.4 -j ah3q@192.168.1.1:main daemon processs
> perl moirai2.pl -b ah3q@192.168.1.5 -j ah3q@192.168.1.1:main daemon processs

##### Nodes and Server Share Same Hard Disk

If the same hard disk are shaed by nodes and server, you can ommit -j option.  All the nodes will look for jobs under /home/ah3q/main/.moirai2 directory.

> cd /home/ah3q/main
> perl moirai2.pl daemon crontab submit
> perl moirai2.pl -b ah3q@192.168.1.2:main daemon processs
> perl moirai2.pl -b ah3q@192.168.1.3:main daemon processs
> perl moirai2.pl -b ah3q@192.168.1.4:main daemon processs
> perl moirai2.pl -b ah3q@192.168.1.5:main daemon processs

##### Openstack (Available soon)

As you know, Moirai2 can create a new instance of node through OpenStack.  By adding '-q openstack', when excessive jobs are found under job directory, new node will be created to process jobs.  And when not jobs are found, instances will be deleted.

> cd /home/ah3q/main
> perl moirai2.pl -q openstack daemon crontab submit process

## Licence

[MIT](https://github.com/tcnksm/tool/blob/master/LICENCE)

## Author

akira.hasegawa@riken.jp