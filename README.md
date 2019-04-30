# Moirai2

## Description

MOIRAI2 is a scientific workflow system.
Commands are all web based (https://moirai2.github.io/command).
Input, output, parameter, time, stdout, stderr are recorded in RDF sqlite3 database.

## Install

To install moirai2 to a directory named "project".

```shell
$ git clone https://github.com/moirai2/moirai2.git project
```

## Usage

```shell
$ perl moirai2.pl CMDURL ARGV [ARGV ..]
```
List of default commands are here:
https://moirai2.github.io/command

## Directory

js/ - Javascript used for MOIRAI2 manipulation through a browser.
moirai2.php - Used for MOIRAI2 manipulation through a browser.
moirai2.pl - Computes MOIRAI2 commands/network.
rdf.pl - Script to handle Resource Description Framework (RDF) using SQLite3 database.

## Licence

[MIT](https://github.com/tcnksm/tool/blob/master/LICENCE)

## Author

akira.hasegawa@riken.jp
