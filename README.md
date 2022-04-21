# Moirai2

## Description

MOIRAI2 is a simple scientific workflow system written in perl to process multiple commands sequentially, keep logs/history of commands, and construct a meta database of files and values (notated with triples) with simple to use bash like notation. 

For example:

> perl moirai2.pl exec ls -lt

This will simply execute 'ls -lt' command and store stdout output, time of executions, and command line in [a log file](example/log.txt) under .moirai2/log directory.

> perl moirai2.pl -o example->file->$output exec echo hello world > $output

This will execute (exec) a command echo hello world > $output and create an output file with a content hello world.
It will also record a triple, example(subject), file(predicate), and filepath to output(object) in text based metadata database. 

> perl moirai2.pl -i example->file->$input -o $input->count->$output exec output=$(wc -l $input)

Based output file (hello world) from the previous execution, it will execute word count (wc) command and store its result in $output variable. 

Also triple (subject=filepath to hello world text file, predicate=count, object=1) will be recorded in metadata database.

Chain commands can be connected by linking triples like examples above. 
## Structure
```
moirai2/
├── commandeditor.html - HTML for editing command json.
├── commandviewer.html - Viewintg a command json.
├── css/ - stylesheet used by jquery columns.
├── images/ - images used by jquery columns.
├── js/ - Javascript used for MOIRAI2 manipulation through a browser.
|   ├── ah3q/ - my javascripts fro moirai2
|   ├── jquery/ - jquery (https://visjs.org) scripts
|   └── vis/ - vis (https://visjs.org) scripts for network graphs
├── moirai2.php - Used for MOIRAI2 manipulation through a browser.
├── moirai2.pl - Computes MOIRAI2 commands/network.
├── rdf.pl - Script to handle Resource Description Framework (RDF) using SQLite3 database.
└── README.md - This readme file
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

## Usage

* Explaining usage by examples.

### Example0
```shell
$ perl moirai2.pl exec ls
README.md
commandeditor.html
commandviewer.html
css
images
js
moirai
moirai2.php
moirai2.pl
rdf.pl
```
* Execute ls command

```shell
$ perl moirai2.pl exec ls -lt
total 480
drwxrwxrwx  8 ah3q  _www      256  9 13 23:30 moirai
-rw-r--r--@ 1 ah3q  _www    22230  9 13 23:29 README.md
drwxrwxrwx  6 ah3q  _www      192  9 13 23:13 js
-rwxrwxrwx@ 1 ah3q  staff  132304  9 13 23:05 moirai2.pl
-rwxrwxrwx@ 1 ah3q  staff   63474  9 13 22:09 rdf.pl
-rwxrwxrwx@ 1 ah3q  _www     7753 12 13  2020 moirai2.php
-rwxr-xr-x@ 1 ah3q  _www     8064 10 23  2020 commandeditor.html
-rwxr-xr-x@ 1 ah3q  _www     3013 10 23  2020 commandviewer.html
drwxr-xr-x  4 ah3q  _www      128 10  8  2020 css
drwxr-xr-x  9 ah3q  _www      288 10  8  2020 images
```

### Example1
```shell
$ perl moirai2.pl https://moirai2.github.io/command/text/sort.json
#Input: input? input.txt
$ ls rdf/nXXXXXXXXXXXXXX
sort.txt
```
* This is an example of a sort command using a json file I prepared: <a href="https://moirai2.github.io/command/text/sort.json">sort.json</a>.
* Path to input file (to be sorted) will be prompted, so enter a filepath and push return.
* Temporary bash shell, stdout, stderr files will be written to rdf/nXXXXXXXXXXXXXX/ (XXXXXXXXXXXXXX is datetime).
* Computation will finish in few seconds.  All (empty) temporary files will be removed.
* After computation, sorted file will be output to rdf/nXXXXXXXXXXXXXX/sort.txt 

### Example2
```shell
$ perl moirai2.pl https://moirai2.github.io/command/text/sort.json input.txt
$ ls rdf/nXXXXXXXXXXXXXX
sort.txt
```
* You can specify input path in argument and can avoid prompt message.

### Example3
```shell
$ perl moirai2.pl https://moirai2.github.io/command/text/sort.json input.txt output.txt
$ ls output.txt
output.txt
```
* It's possible to specify both input and output paths.
* Order of arguments do matter and differ by commands.

### Example4
* Order of input and output in arguments can be checked with a help option.
```shell
$perl moirai2.pl -h https://moirai2.github.io/command/text/sort.json

#URL     :https://moirai2.github.io/command/text/sort.json
#Command :sort.json [input] [output]
#Input   :input
#Output  :output
#Bash    :output="$workdir/sort.txt"
         :sort $input > $output
```
* In sort.json case, first argument is 'input' and second argument is 'output'.
* help option without any json URL will print out ordinary help message.
```shell
$perl moirai2.pl -h

############################## HELP ##############################

Program: Handles MOIRAI2 command with SQLITE3 database.
Version: 2020/11/05
Author: Akira Hasegawa (akira.hasegawa@riken.jp)

Usage: perl moirai2.pl [Options] COMMAND

Commands: daemon   Run daemon
          file     Checks file information
          ls       list directories/files
          command  Execute from user specified command instead of a command json
          loop     Loop check and execution indefinitely 
          script   Retrieve scripts and bash files from a command json
          test     For development purpose
.....
```
* help option without a command will show more specific help message
```shell
$perl moirai2.pl -h ls

############################## HELP ##############################

Program: List files/directories and store path information to DB.

Usage: perl moirai2.pl [Options] ls DIR DIR2 ..

        DIR  Directory to search for (if not specified, DIR='.').

Options: -d  RDF sqlite3 database (default='rdf.sqlite3').
         -g  grep specific string
         -G  ungrep specific string
         -o  Output query for insert in '$sub->$pred->$obj' format.
         -r  Recursive search (default=0)

Variables: $path, $directory, $filename, $basename, $suffix, $dirX (X=0~9), $baseX (X=0~9)

Example: perl moirai2.pl -d DB -r 0 -g GREP -G UNREP -o '$basename->#id->$path' ls DIR DIR2 ..

```

### Example5
```shell
$ perl moirai2.pl https://moirai2.github.io/command/text/sort.json input=input.txt output=output.txt
$ ls output.txt
output.txt
```
* You can specify input and output with "key=value" notation.
* Order doesn't matter if variable format is used.
* Notation can be either input=input.txt or '$input=input.txt' (be sure to use single quote when $ is used).
* To know the valid input and output variable names use a help command explained in Example4.

### Example6
```shell
$ cat sort.json
{"https://moirai2.github.io/schema/daemon/input":"$input",
"https://moirai2.github.io/schema/daemon/bash":["output=\"$workdir/sort.txt\"","sort $input > $output"],
"https://moirai2.github.io/schema/daemon/output":"$output"}
$ perl moirai2.pl sort.json
#Input: input? input.txt
$ ls output.txt
output.txt
```
* You can run a command from a json file in your local directory.  Json file doesn't have to be on the web.
* A command json file used in the previous usage, specifies command lines, input, and output.
* I have prepared basic commands at <a href="https://moirai2.github.io/command">https://moirai2.github.io/command</a>.
* You can create your own command json file and use them.
* https://moirai2.github.io/schema/daemon/input - For multiple values, ["$input1","$input2"]
* https://moirai2.github.io/schema/daemon/bash - MAKE SURE you assign the output variables in your code.
* https://moirai2.github.io/schema/daemon/output -  To specify multiple value, "$output1,$output2" is ok too.

### Example7
* Information of an execution is stored in the Resource Description Framework (RDF) database (https://en.wikipedia.org/wiki/Resource_Description_Framework).
* Data are store din RDF triples (subject, predicate, object).
* You can view the RDF database by rdf.pl script with select (% is wildcard):
```shell
$ perl rdf.pl select
n20201119134907	https://moirai2.github.io/command/text/sort.json#input	input.txt
n20201119134907	https://moirai2.github.io/command/text/sort.json#output	rdf/n20201119134907/sort.txt
n20201119134907	https://moirai2.github.io/schema/daemon/command	https://moirai2.github.io/command/text/sort.json
n20201119134907	https://moirai2.github.io/schema/daemon/timeended	1605761347
n20201119134907	https://moirai2.github.io/schema/daemon/timestarted	1605761347
n20201119134907	https://moirai2.github.io/schema/daemon/timethrown	1605761347
$ perl rdf.pl select % https://moirai2.github.io/schema/daemon/command
n20201119134907	https://moirai2.github.io/schema/daemon/command	https://moirai2.github.io/command/text/sort.json
$ perl rdf.pl select % % input.txt
n20201119134907	https://moirai2.github.io/command/text/sort.json#input	input.txt
```

### Example8
* Following are examples using database for controlling executions.
* You can store the results/filepaths of computation in RDF database with -o option.
```shell
$perl moirai2.pl -o '$input->sorted->$output' https://moirai2.github.io/command/text/sort.json input=input.txt output=sorted.txt
$ perl rdf.pl select
input.txt	sorted	sorted.txt
n20201119135641	https://moirai2.github.io/command/text/sort.json#input	input.txt
n20201119135641	https://moirai2.github.io/command/text/sort.json#output	sorted.txt
n20201119135641	https://moirai2.github.io/schema/daemon/command	https://moirai2.github.io/command/text/sort.json
n20201119135641	https://moirai2.github.io/schema/daemon/timeended	1605761801
n20201119135641	https://moirai2.github.io/schema/daemon/timestarted	1605761801
n20201119135641	https://moirai2.github.io/schema/daemon/timethrown	1605761801
```
* Output option format is 'subject->predicate->object'.
* Variables ($input and $output) need to be matched with variables specified in command lines.
* Be sure to use single quotes (') instead of double quotes (") when specifying output format.  Otherwise $input and $output will be treated as bash variables (bash tries to assign values to $input and $output resulting in empty values).
* If you really want to use double quotes, Be sure to add '\' before '$'.
```shell
$perl moirai2.pl -o "\$input->sorted->\$output" https://moirai2.github.io/command/text/sort.json input=input.txt output=sorted.txt
```

### Example9
* With -i option, variable values can be referenced from the database.
* Using result from previous example:
```shell
$ perl rdf.pl select % sorted
input.txt	sorted	sorted.txt
$perl moirai2.pl -i '$original->sorted->$input' -o '$input->resorted->$output' https://moirai2.github.io/command/text/sort.json output=resorted.txt
$ perl rdf.pl select % %sorted
input.txt	sorted	sorted.txt
sorted.txt	resorted	resorted.txt
```
* If there are multiple data assigned in the database, all the commands will be executed.
```shell
$ perl rdf.pl select % sorted
input.txt	sorted	sorted.txt
input2.txt	sorted	sorted2.txt
$perl moirai2.pl -i '$original->sorted->$input' -o '$input->resorted->$output' https://moirai2.github.io/command/text/sort.json 'output=${input.basename}.resorted.txt'
$ perl rdf.pl select % %sorted
input.txt	sorted	sorted.txt
input2.txt	sorted	sorted2.txt
sorted.txt	resorted	sorted.resorted.txt
sorted2.txt	resorted	sorted2.resorted.txt
```

### Example10
* By joining input and output notations of commands, the pipeline/workflow can be created.
```shell
$ cat workflow.sh
mkdir -p grepped
mkdir -p sorted
mkdir -p uniqued
$perl moirai2.pl -o 'workflow->input->$path' input
$perl moirai2.pl -i '$hoge->input->$input' -o '$input->grepped->$output' https://moirai2.github.io/command/text/grep.json 'output=grepped/${input.filename}' 'pattern=moirai2'
$perl moirai2.pl -i '$hoge->grepped->$input' -o '$input->sorted->$output' https://moirai2.github.io/command/text/sort.json 'output=sorted/${input.filename}'
$perl moirai2.pl -i '$hoge->sorted->$input' -o '$input->uniqued->$output' https://moirai2.github.io/command/text/uniq_c.json 'output=uniqued/${input.filename}'
```
  * This line adds files under input directory to the database.
  * If there are A.txt and B.txt under input/ directory, 'workflow->input->input/A.txt' and 'workflow->input->input/B.txt' will be added to the database.
```shell
$perl moirai2.pl -o 'workflow->input->$path' input
```

### Example11
* The command lines don't have to be specified through json.
```shell
$ perl moirai2.pl -i '$original->resorted->$file' -o '$file->wc-l->$result' command << 'EOS'
result=$workdir/${file.basename}.txt
wc -l < $file > $result
EOS
```
* Command lines are specified using here document (https://en.wikipedia.org/wiki/Here_document).
* Don't forget to quote EOS with single quote (').  'EOS' make sure $file will be treated as $file instead of actual variable by BASH script.
* Variables can be either $XXXX or ${XXXX} (same as bash notation)
* system variables:
  * cmdurl - "https://moirai2.github.io/command/text/sort.json"
  * rdfdb - "rdf.sqlite3"
  * nodeid - "nXXXXXXXXXXXXXX"
  * ctrldir - Full path to "rdf/ctrl"
  * prgdir - Full path to where moirai2.pl and rdf.pl are located
  * rootdir - Full path to where rdf.sqlite3 is located
  * tmpdir - "rdf/nXXXXXXXXXXXXXX/tmp"
  * workdir - "rdf/nXXXXXXXXXXXXXX"
* file exentions (These will be replaced by moirai2.pl):
  * .path - "/A/B/C/D_E_F.fa"
  * .directory - "/A/B/C"
  * .filename - "D_E_F.fa"
  * .basename - "D_E_F"
  * .suffix - "fa"
  * .baseX (X=int) - separated by non alphabet/number.  base0="D", base1="E", base2="F"
  * .dirX (X=int) - separated by '/'.  dir0="A", dir1="B", dir2="C"

## Scripts

### moirai2.pl
#### main
```shell
Program: Handles MOIRAI2 command with SQLITE3 database.
Version: 2020/11/05
Author: Akira Hasegawa (akira.hasegawa@riken.jp)

Usage: perl moirai2.pl [Options] COMMAND

Commands: daemon   Run daemon
          file     Checks file information
          ls       list directories/files
          command  Execute from user specified command instead of a command json
          loop     Loop check and execution indefinitely 
          script   Retrieve scripts and bash files from a command json
          test     For development purpose
```

#### default
```shell
Program: Executes MOIRAI2 command of a spcified URL json.

Usage: perl moirai2.pl [Options] JSON/BASH [ASSIGN/ARGV ..]

       JSON  URL or path to a command json file (from https://moirai2.github.io/command/).
       BASH  URL or path to a command bash file (from https://moirai2.github.io/workflow/).
     ASSIGN  Assign a MOIRAI2 variables with '$VAR=VALUE' format.
       ARGV  Arguments for input/output parameters.

Options: -c  Use container for execution [docker,udocker,singularity].
         -d  RDF sqlite3 database (default='rdf.sqlite3').
         -h  Show help message.
         -H  Show update history.
         -i  Input query for select in '$sub->$pred->$obj' format.
         -l  Show STDERR and STDOUT logs.
         -m  Max number of jobs to throw (default='5').
         -o  Output query for insert in '$sub->$pred->$obj' format.
         -p  Prompt input parameter(s) to user.
         -q  Use qsub for throwing jobs.
         -r  Print return value.
         -s  Loop second (default='10').
```

#### file
```shell
Program: Check and store file information to the database.

Usage: perl moirai2.pl [Options] file

Options: -d  RDF sqlite3 database (default='rdf.sqlite3').
         -i  Input query for select in '$sub->$pred->$obj' format.
         -o  Output query for insert in '$sub->$pred->$obj' format.

Variables:
  $linecount   Print line count of a file (Can take care of gzip and bzip2).
  $seqcount    Print sequence count of a FASTA/FASTQ files.
  $filesize    Print size of a file.
  $md5         Print MD5 of a file.
  $timestamp   Print time stamp of a file.
  $owner       Print owner of a file.
  $group       Print group of a file.
  $permission  Print permission of a file.
```

#### ls
```shell
Program: List files/directories and store path information to DB.

Usage: perl moirai2.pl [Options] ls DIR DIR2 ..

        DIR  Directory to search for (if not specified, DIR='.').

Options: -d  RDF sqlite3 database (default='rdf.sqlite3').
         -g  grep specific string
         -G  ungrep specific string
         -o  Output query for insert in '$sub->$pred->$obj' format.
         -r  Recursive search (default=0)

Variables: $path, $directory, $filename, $basename, $suffix, $dirX (X=0~9), $baseX (X=0~9)
```

#### command
```shell
Usage: perl moirai2.pl [Options] command [ASSIGN ..] << 'EOS'
COMMAND ..
COMMAND2 ..
EOS

     ASSIGN  Assign a MOIRAI2 variables with '$VAR=VALUE' format.
    COMMAND  Bash command lines to execute.
        EOS  Assign command lines with Unix's heredoc.

Options: -c  Use container for execution [docker,udocker,singularity].
         -d  RDF sqlite3 database (default='rdf.sqlite3').
         -i  Input query for select in '$sub->$pred->$obj' format.
         -l  Show STDERR and STDOUT logs.
         -m  Max number of jobs to throw (default='5').
         -o  Output query for insert in '$sub->$pred->$obj' format.
         -q  Use qsub for throwing jobs.
         -r  Print return value.
         -s  Loop second (default='10').
```

#### loop
```shell
Program: Check for Moirai2 commands every X seconds and execute.

Usage: perl moirai2.pl [Options] loop

Options: -d  RDF sqlite3 database (default='rdf.sqlite3').
         -l  Show STDERR and STDOUT logs.
         -m  Max number of jobs to throw (default='5').
         -q  Use qsub for throwing jobs(default='bash').
         -s  Loop second (default='no loop').
```

#### script
```shell
Program: Retrieves script and bash files from URL and save them to a directory.

Usage: perl moirai2.pl [Options] script JSON

       JSON  URL or path to a command json file (from https://moirai2.github.io/command/).

Options: -o  Output directory (default='.').
```

### rdf.pl

#### sync
```shell
rdf.pl -d DB sync
```
* Convert db directory/files <=> RDF sqlite3 DB.
* This command checks timestamp of sqlite3 database file and text triplet files under db directory.
* If timestamp of sqlite3 database is latest, it'll proceed "save" command.
* If time stamp of triplet files under db directory are the latest, it'll proceed "load" command.

#### save
```shell
rdf.pl -d DB save
```
* Convert RDF sqlite3 DB => db directory/files.
* All the triplets stored in sqlite3 database will be written to triplet files.
* Triplet files are grouped by predicate.
* For example:
  * Triplet "A->B->C" will be stored under db/B.txt file.
  * Triplet "A->http://moirai2.gsc.riken.jp/akira/B->C" will be stored under db/moirai2.gsc.rien.jp/akira/B.txt file.
  * Triplet "A->B#C->D" will be stored under db/B.txt file.
* Unused triplet files will be removed.

#### load
```shell
rdf.pl -d DB load
```
* Convert db directory/files => RDF sqlite3 DB.
* All the files under db directory will be loaded.
* The triplet files doesn't have to be grouped by the predicate.
* Filename can be anything.
* Sqlite3 database will be reset and reloaded with triplet under db directory files.

#### select
```shell
rdf.pl -d DB select SUB PRE OBJ
```
* Select database subject, predicate, object.
* Use '%' for a wildcard.
```shell
A->B->C

> rdf.pl -d DB select A B C
A B C
> rdf.pl -d DB select A B %
A B C
> rdf.pl -d DB select % % C
A B C
```

#### insert
```shell
rdf.pl -d DB insert SUB PRE OBJ
```
* Insert a new RDF (subject, predicate, object).
```shell
> rdf.pl -d DB insert D E F
inserted 1
```

#### update
```shell
rdf.pl -d DB update SUB PRE OBJ
```
* Update/replace new object with defined subject and predicate.
```shell
A->B->C

>rdf.pl -d DB update A B D
updated 1

A->B->D
```

#### delete
```shell
rdf.pl -d DB delete SUB PRE OBJ
```
* Delete RDF with defined subject, predicate, and object.
```shell
A->B->C

>rdf.pl -d DB delete A B C
deleted 1
```

#### object
```shell
rdf.pl -d DB object SUB PRE OBJ > VARIABLE
```
* Print out object with specified subject, predicate, and object.
* If there are multiple objects, results will be printed out in one line with a space.
```shell
A->B->C
A->B->D

>rdf.pl -d DB object A B
C D
```

#### network
```shell
rdf.pl -d DB network > TSV
```
* Print all triplets excluding moirai2 system.
```shell
A->B->C
A->B->D

> rdf.pl -d DB network
A   B   C
A   B   D
```

#### network
```shell
rdf.pl -d DB import < TSV
```
* Import RDF from TSV.
```shell
> tsv.txt
A   B   C
D   E   F

>rdf.pl -d DB import < tsv.txt
A->B->C
D->E->F
```

#### dump
```shell
rdf.pl -d DB dump > TSV
```
* Dump database in TSV format.
```shell
A->B->C
D->E->F

>rdf.pl -d DB dump > TSV
A   B   C
D   E   F
```
* Dump database in JSON format.
```shell
rdf.pl -d DB -f json dump > JSON
```

#### drop
* Delete the table
```shell
rdf.pl -d DB drop
```

#### query
```shell
rdf.pl -d DB query QUERY > JSON
```
* Get key-val from database with a query.
```shell
A   B   C

>perl rdf.pl query 'A->B->$c'
[{"c":"C"}]
```

#### replace
```shell
rdf.pl -d DB replace FROM TO
```
* Replace node with a new value.
```shell
A   B   C

rdf.pl -d DB replace C D
replaced

A   B   D
```

#### mv
```shell
rdf.pl -d DB mv FROM TO
```
* Replace variable in database and also move file to a new path.
```shell
A B C.txt

rdf.pl -d DB mv C.txt D.txt

A B D.txt
move C.txt to D.txt
```

#### rm
```shell
rdf.pl -d DB rm PATH
```
* Remove a file and record.
```shell
A B C.txt

rdf.pl -d DB rm C.txt

C.txt	https://moirai2.github.io/schema/file/timeremoved	1595086775
remove C.txt
```

#### newnode
```shell
rdf.pl -d DB newnode > NODE
```
# Create a new node ID.
```shell
> rdf.pl -d DB newnode
rdf.sqlite3#node1
```

#### reindex
```shell
rdf.pl -d DB reindex
```
* Reindex database.

#### download
```shell
rdf.pl -d DB download URL
```
* Download a file path and record information.

#### command
```shell
rdf.pl -d DB -f json command < JSON
```
* Register execution of a command in the database.
* Run a command with moirai2.pl.

#### merge
```shell
rdf.pl -d DB merge DB2 DB3
```
* Merge database and database arguments.

#### linecount
```shell
rdf.pl linecount DIR/FILE > TSV
```
* Count lines and register number.

#### seqcount
```shell
rdf.pl seqcount DIR/FILE > TSV
```
* Count sequences and register number.

#### filesize
```shell
rdf.pl filesize DIR/FILE > TSV
```
* Check file size and register.

#### md5
```shell
rdf.pl md5 DIR/FILE > TSV
```
* Check md5 and register.

#### ls
```shell
rdf.pl ls DIR/FILE > LIST
```
* List directory and register database.

```shell
rdf.pl -d DB ls '-' < STDIN
```

#### copy
```shell
rdf.pl -d DB -D DB2 copy QUERY
```
* Copy database to a new database with query.

#### install
```shell
rdf.pl -d DB install URL
```
* Install software URL.

#### rmexec
```shell
rdf.pl -d DB rmexec
```
* Remove currently running executes.

#### input
```shell
rdf.pl -d DB input SUB PRE OBJECT OBJECT2 [..]
```
* Input multiple objects.

#### prompt
```shell
rdf.pl -d DB prompt SUB PRE QUESTION DEFAULT
```
* Prompt and new triplet to RDF database.
* SUB->PRE->[user defined] will be inserted.
* When [return] is typed, DEFAULT will be used instead.
* When user typed value.
```shell
> rdf.pl prompt A B "What is object?" C
What is object? something
> rdf.pl select 
A   B   something
```
* When user just hit return.
```shell
> rdf.pl prompt A B "What is object?" C
What is object?
> rdf.pl select 
A   B   C
```
#### executes
```shell
rdf.pl -d DB executes
```
* Output execute information.

#### html
```shell
rdf.pl -d DB html
```
* Output execute information in html mode.

#### history
```shell
rdf.pl -d DB history
```
* Output execute information in shell mode.

## Licence

[MIT](https://github.com/tcnksm/tool/blob/master/LICENCE)

## Author

akira.hasegawa@riken.jp