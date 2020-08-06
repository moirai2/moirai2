# Moirai2

## Description

MOIRAI2 is a scientific workflow system.
Commands are all web based (https://moirai2.github.io/command).
Input, output, parameter, time, stdout, stderr are recorded in RDF sqlite3 database.

bash2cwl has moved to https://github.com/moirai2/bash2cwl


## Structure
```
moirai2/
├── commandeditor.html - HTML for editing command json.
├── commandviewer.html - Viewintg a command json.
├── js/ - Javascript used for MOIRAI2 manipulation through a browser.
├── moirai2.php - Used for MOIRAI2 manipulation through a browser.
├── moirai2.pl - Computes MOIRAI2 commands/network.
├── rdf.pl - Script to handle Resource Description Framework (RDF) using SQLite3 database.
├── README.md - This readme file
├── bin/ - Stores binary executables (automatically made when running moirai2)
├── ctrl/ - Stores ctrl (example, stdout and stderrr) files (automatically made when running moirai2)
└── work/ - Work directory to store output files (automatically made when running moirai2)
```

## Install

To install moirai2 to a directory named "project".

```shell
$ git clone https://github.com/moirai2/moirai2.git project
```

## Usage

* To sort a file using a <a href="https://moirai2.github.io/command/text/sort.json">sort.json</a>.
* Input will be prompted, so enter a filepath and push return.
* Temporary bash shell, stdout, stderr files will be written to work/sort.XXXXXXXXX/ (XXXXXXXXX is random).
* After computation, sorted file will be output to work/sort.XXXXXXXXX/sort.txt 
```shell
$ perl moirai2.pl https://moirai2.github.io/command/text/sort.json
#Input: input? input.txt
```

* A command json file used in the previous usage, specifies command lines, input, and output.
* I have prepared basic command lines at <a href="https://moirai2.github.io/command">https://moirai2.github.io/command</a>.
* You can create your own command json file and use from a local directory or your website.
```shell
{
"https://moirai2.github.io/schema/daemon/input":"$input",
"https://moirai2.github.io/schema/daemon/bash":["output=\"$workdir/sort.txt\"","sort $input > $output"],
"https://moirai2.github.io/schema/daemon/output":"$output"
}
```

* Path to input file can be assigned through argument, so you can skip prompt part.
```shell
$ perl moirai2.pl https://moirai2.github.io/command/text/sort.json input.txt
```

* By assigning output path, result will not be output to temporary file, but instead location can be specified.
```shell
$ perl moirai2.pl https://moirai2.github.io/command/text/sort.json input.txt output.txt
```

* In any cases, executed information will be stored in the Resource Description Framework (RDF) database.
* You can view the database by rdf.pl.
* Default database path is ./rdf.sqlite3.
* All information are store din RDF triplet (subject, predicate, object).
```shell
$ perl rdf.pl select
rdf.sqlite3#node1	https://moirai2.github.io/schema/daemon/command	https://moirai2.github.io/command/text/sort.json
rdf.sqlite3#node1	https://moirai2.github.io/command/text/sort.json#output	ouput.txt
rdf.sqlite3#node1	https://moirai2.github.io/command/text/sort.json#input	input/sn/sn_RNA_1.fa
rdf.sqlite3#node1	https://moirai2.github.io/schema/daemon/timethrown	1595992099
rdf.sqlite3#node1	https://moirai2.github.io/schema/daemon/timestarted	1595992099
rdf.sqlite3#node1	https://moirai2.github.io/schema/daemon/timeended	1595992099
```

* To see the information about the command JSON, use help option.
* Order of input/output are specified in '#Command' line.
```shell
$ perl moirai2.pl -h https://moirai2.github.io/command/text/sort.json

#URL     :https://moirai2.github.io/command/text/sort.json
#Command :sort.json [input] [output]
#Input   :input
#Output  :output
#Bash    :output="$workdir/sort.txt"
         :sort $input > $output
```

* Strength of moirai2 is commands can run from data store in the RDF database.
* Let's say there are information in the database.
```shell

```

* The command lines don't have to be specified through json.
```shell
$ perl moirai2.pl -i 'A->B->$file' -o '$file->C->$result' exec << 'EOS'
result=wc/${file.basename}.txt
wc -l < $file > $result
EOS
```

### moirai2.pl

```shell
$ perl moirai2.pl CMDURL ARGV [ARGV ..]
```
List of default commands are here:
https://moirai2.github.io/command

### rdf.pl

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
* Print all RDF other than system RDF.
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
