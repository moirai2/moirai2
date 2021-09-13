#!/usr/bin/perl
use strict 'vars';
use Cwd;
use File::Basename;
use File::Temp;
use FileHandle;
use Getopt::Std;
use LWP::UserAgent;
use HTTP::Request;
use Time::Local;
use Time::localtime;
use File::Temp qw/tempfile tempdir/;
############################## HEADER ##############################
my ($program_name,$prgdir,$program_suffix)=fileparse($0);
$prgdir=Cwd::abs_path($prgdir);
my $program_path="$prgdir/$program_name";
my $program_version="2021/09/13";
############################## OPTIONS ##############################
use vars qw($opt_a $opt_b $opt_c $opt_d $opt_E $opt_f $opt_F $opt_g $opt_G $opt_h $opt_H $opt_i $opt_l $opt_m $opt_o $opt_O $opt_p $opt_q $opt_Q $opt_r $opt_s $opt_S $opt_u);
getopts('a:b:c:d:E:f:F:g:G:hHi:lm:o:O:pq:Q:r:s:S:u');
############################## URLs ##############################
my $urls={};
$urls->{"daemon"}="https://moirai2.github.io/schema/daemon";
$urls->{"daemon/bash"}="https://moirai2.github.io/schema/daemon/bash";
$urls->{"daemon/command"}="https://moirai2.github.io/schema/daemon/command";
$urls->{"daemon/command/option"}="https://moirai2.github.io/schema/daemon/command/option";
$urls->{"daemon/container"}="https://moirai2.github.io/schema/daemon/container";
$urls->{"daemon/description"}="https://moirai2.github.io/schema/daemon/description";
$urls->{"daemon/execid"}="https://moirai2.github.io/schema/daemon/execid";
$urls->{"daemon/execute"}="https://moirai2.github.io/schema/daemon/execute";
$urls->{"daemon/error/file/empty"}="https://moirai2.github.io/schema/daemon/error/file/empty";
$urls->{"daemon/error/stderr/ignore"}="https://moirai2.github.io/schema/daemon/error/stderr/ignore";
$urls->{"daemon/error/stdout/ignore"}="https://moirai2.github.io/schema/daemon/error/stdout/ignore";
$urls->{"daemon/file/md5"}="https://moirai2.github.io/schema/daemon/file/md5";
$urls->{"daemon/file/filesize"}="https://moirai2.github.io/schema/daemon/file/filesize";
$urls->{"daemon/file/linecount"}="https://moirai2.github.io/schema/daemon/file/linecount";
$urls->{"daemon/file/seqcount"}="https://moirai2.github.io/schema/daemon/file/seqcount";
$urls->{"daemon/file/stats"}="https://moirai2.github.io/schema/daemon/file/stats";
$urls->{"daemon/filestats"}="https://moirai2.github.io/schema/daemon/filestats";
$urls->{"daemon/input"}="https://moirai2.github.io/schema/daemon/input";
$urls->{"daemon/inputs"}="https://moirai2.github.io/schema/daemon/inputs";
$urls->{"daemon/maxjob"}="https://moirai2.github.io/schema/daemon/maxjob";
$urls->{"daemon/output"}="https://moirai2.github.io/schema/daemon/output";
$urls->{"daemon/process/lastupdate"}="https://moirai2.github.io/schema/daemon/process/lastupdate";
$urls->{"daemon/processtime"}="https://moirai2.github.io/schema/daemon/processtime";
$urls->{"daemon/qjob"}="https://moirai2.github.io/schema/daemon/qjob";
$urls->{"daemon/qjob/opt"}="https://moirai2.github.io/schema/daemon/qjob/opt";
$urls->{"daemon/return"}="https://moirai2.github.io/schema/daemon/return";
$urls->{"daemon/script"}="https://moirai2.github.io/schema/daemon/script";
$urls->{"daemon/script/code"}="https://moirai2.github.io/schema/daemon/script/code";
$urls->{"daemon/script/name"}="https://moirai2.github.io/schema/daemon/script/name";
$urls->{"daemon/server"}="https://moirai2.github.io/schema/daemon/server";
$urls->{"daemon/singlethread"}="https://moirai2.github.io/schema/daemon/singlethread";
$urls->{"daemon/suffix"}="https://moirai2.github.io/schema/daemon/suffix";
$urls->{"daemon/timecompleted"}="https://moirai2.github.io/schema/daemon/timecompleted";
$urls->{"daemon/timeended"}="https://moirai2.github.io/schema/daemon/timeended";
$urls->{"daemon/timeregistered"}="https://moirai2.github.io/schema/daemon/timeregistered";
$urls->{"daemon/timestarted"}="https://moirai2.github.io/schema/daemon/timestarted";
$urls->{"daemon/unzip"}="https://moirai2.github.io/schema/daemon/unzip";
$urls->{"daemon/username"}="https://moirai2.github.io/schema/daemon/username";
$urls->{"daemon/workdir"}="https://moirai2.github.io/schema/daemon/workdir";
############################## HELP ##############################
sub help{
	print "\n";
	print "############################## HELP ##############################\n";
	print "\n";
	print "Program: Handles Moirai2 workflow/command using triple database.\n";
	print "Version: $program_version\n";
	print "Author: Akira Hasegawa (akira.hasegawa\@riken.jp)\n";
	print "\n";
	print "Usage: perl $program_name [Options] COMMAND\n";
	print "\n";
	print "Commands:\n";
	print "          automate  Run bash script located under ctrl/automate directory\n";
	print "          (?)check  Check if values specified in input options are same\n";
	print "           command  Execute user specified command from STDIN\n";
	print "            daemon  Look for moirai2 ctrl directories and run automate if there were updates\n";
	print "              exec  Execute user specified command from ARGUMENTS\n";
	print "           extract  Extract scripts and bash files from a command json URL\n";
	print "              html  Create a HTML representation of triple database\n";
	print "                ls  Create triples from directories/files and show or store them in triple database\n";
	print "          progress  Print out progress\n";
	print "              test  For development purpose (test commands)\n";
	print "\n";
	print "############################## Default Usage ##############################\n";
	print "\n";
	print "Program: Executes MOIRAI2 command of a spcified URL json.\n";
	print "\n";
	print "Usage: perl $program_name [Options] JSON/BASH [ASSIGN/ARGV ..]\n";
	print "\n";
	print "       JSON  URL or path to a command json file (from https://moirai2.github.io/command/).\n";
	print "       BASH  URL or path to a command bash file (from https://moirai2.github.io/workflow/).\n";
	print "     ASSIGN  Assign a MOIRAI2 variables with '\$VAR=VALUE' format.\n";
	print "       ARGV  Arguments for input/output parameters.\n";
	print "\n";
	print "Options: -a  (A)ccess server and compute (default=local computer).\n";
	print "         -b  Specify (b)oolean options when running a command line (example -a:\$optionA,-b:\$optionB).\n\n";
	print "         -c  Use (c)ontainer image for execution [docker|singularity].\n";
	print "         -d  Triple (d)atabase directory (default='moirai').\n";
	print "         -E  Ignore STD(E)RR if specific regexp is found.\n";
	print "         -f  Record (f)ilestats[linecount/seqcount/md5/filesize/utime] of input/output files.\n";
	print "         -F  If specified output (f)ile is empty, record as error.\n";
	print "         -g  (G)rep string\n";
	print "         -G  Un(g)rep string when \n";
	print "         -h  Show (h)elp message.\n";
	print "         -H  Show update (h)istory.\n";
	print "         -i  (I)nput query for select from database in '\$sub->\$pred->\$obj' format.\n";
	print "         -l  Show (l)ogs from moirai.pl.\n";
	print "         -m  (M)ax number of jobs to throw (default='5').\n";
	print "         -o  (O)utput query for insert to database in '\$sub->\$pred->\$obj' format.\n";
	print "         -O  Ignore STD(O)UT if specific regexp is found.\n";
	print "         -p  (P)rint command lines instead of executing.\n";
	print "         -q  Use (q)sub or slurm for throwing jobs [qsub|slurm].\n";
	print "         -Q  (Q)sub/slurm options [qsub/sge/squeue/slurm].\n";
	print "         -r  Print (r)eturn value (in exec mode, stdout is default).\n";
	print "         -s  Loop (s)econd (default='10').\n";
	print "         -S  Implement/import (s)cript code to a command json file.\n";
	print "         -u  Run in (U)ser mode where input parameters are prompted.\n";
	print "\n";
	if(defined($opt_H)){
		print "############################## Examples ##############################\n";
		print "\n";
		print "(1) perl $program_name https://moirai2.github.io/command/text/sort.json\n";
		print "\n";
		print "  - Executes a sort command with user prompt for input.\n";
		print "\n";
		print "(2) perl $program_name -h https://moirai2.github.io/command/text/sort.json\n";
		print "\n";
		print "  - Shows information of a command.\n";
		print "\n";
		print "(3) perl $program_name https://moirai2.github.io/command/text/sort.json input.txt\n";
		print "\n";
		print "  - Executes a sort command by specifying input with arguments.\n";
		print "  - Output will be sotred in moirai/work.YYYYMMDDHHMMSS/tmp/ directory.\n";
		print "  - moirai log will be stored under moirai/log/YYYYMMDD.\n";
		print "  - moirai error log will be stored under moirai/log/error.\n";
		print "\n";
		print "(4) perl $program_name https://moirai2.github.io/command/text/sort.json input.txt output.txt\n";
		print "\n";
		print "  - Executes a sort command by specifying input and output with arguments.\n";
		print "  - By specifying output path in argument, output will be saved at specified path.\n";
		print "\n";
		print "(5) perl $program_name https://moirai2.github.io/command/text/sort.json '\$input=input.txt' '\$output=output.txt'\n";
		print "\n";
		print "  - Executes a sort command by specifying input and output with variables.\n";
		print "  - Input and output variables can be assigned with '='.\n";
		print "\n";
		print "(6) perl $program_name -o 'A->input->\$file' ls *.txt\n";
		print "\n";
		print "  - Stores 'A->input->input.txt' if there is a input.txt under a root directory.\n";
		print "  - DB triple will be stored under moirai/db/input.txt.\n";
		print "  - Column1 is subject, file basename is predicate, and column2 is object\n";
		print "\n";
		print "(7) perl $program_name -i 'A->input->\$input' -o 'A->sort->\$output' https://moirai2.github.io/command/text/sort.json\n";
		print "\n";
		print "  - Executes a sort command with \$input from 'A->input->\$input' triple information.\n";
		print "  - Sorted file will be created with path: moirai/eYYYYMMDDHHMMSS/tmp/sort.txt.\n";
		print "  - New 'A->output->moirai/eYYYYMMDDHHMMSS/tmp/sort.txt' triple will be written on 'moirai/db/sort.txt'.\n";
		print "\n";
		print "(8) echo 'output=\$tmpdir/uniq.txt;uniq \$input > \$output' | perl $program_name -i 'A->sort->\$input' -o '\$input->uniq->\$output' command\n";
		print "\n";
		print "  - Command information can be assigned by user with STDIN.\n";
		print "  - Uniq file will be created with path: moirai/eYYYYMMDDHHMMSS/tmp/uniq.txt.\n";
		print "  - You need to assign \$output variable with in command lines.\n";
		print "  - New 'moirai/eYYYYMMDDHHMMSS/tmp/sort.txt->uniq->moirai/eYYYYMMDDHHMMSS/tmp/uniq.txt' triple will be written on 'moirai/db/uniq.txt'.\n";
		print "\n";
		print "(9) perl $program_name -i '\$sort->uniq->\$input' -o '\$input->count->\$count' command << 'EOS'\n";
		print "count=`wc -l<\$input`\n";
		print "EOS\n";
		print "\n";
		print "  - EOS can be used to assign command lines.  Make sure quote EOS with '\n";
		print "  - New 'moirai/eYYYYMMDDHHMMSS/tmp/uniq.txt->count->XXXXX' triple will be written on 'moirai/db/count.txt'.\n";
		print "\n";
		print "System variables which can be used in moirai2:\n";
		print "     \$1~\$9  arguments passed\n";
		print "     \$stdin  STDIN content\n";
		print "    \$stdout  STDOUT content\n";
		print "    \$stderr  STDERR content\n";
		print "\$stdoutfile  Path to STDOUT file\n";
		print "\$stderrfile  Path to STDERR file\n";
		print "\n";
		print "Note:  -b is used to specify command option without any value.\n";
		print "       'grep -v' for example, '-v' doesn't have a following value.\n";
		print "       By linking option and variable with \"-b '-v:\$reverse'\",\n";
		print "       '-v' will be added when \$reverse variable is defined.\n";
		print "\n";
		print "       To throw jobs using SGE (Sun Grid Engine) through SSH (Secure Shell),\n";
		print "       you need to specify SGE_ROOT and PATH in your .bashrc file like following:\n";
		print "       export SGE_ROOT=[sge root directory]\n";
		print "       export PATH=[qsub bin directory]:\$PATH\n";
		print "\n";
		print "       In my environment, I configure SGE setting like this:\n";
		print "       export SGE_ROOT=/opt/SoGE/\n";
		print "       export PATH=\$HOME/bin:/opt/SoGE/bin/lx-amd64/:\$PATH\n";
		print "\n";
		print "############################## Updates ##############################\n";
		print "\n";
		print "2021/08/28  Execute command line across SSH/SCP\n";
		print "2021/08/25  Modified job completion process\n";
		print "2021/07/06  Add import script functionality when creating json file\n";
		print "2021/05/18  Slurm option added to bashCommand\n";
		print "2021/01/08  Added stdout/stderr error handlers with options.\n";
		print "2021/01/04  Added 'boolean options' to enable options without values.\n";
		print "2020/12/17  'filestats' command added to check values.\n";
		print "2020/12/16  'check' command added to check values.\n";
		print "2020/12/15  'html' command  added to report workflow in HTML format.\n";
		print "2020/12/14  Create and keep json file from user defined command\n";
		print "2020/12/13  'empty output' and 'ignore stderr/stout' functions added.\n";
		print "2020/12/12  stdout and stderr reports are appended to a log file.\n";
		print "2020/12/01  Adapt to new rdf.pl which doens't user sqlite3 database.\n";
		print "2020/11/20  Import and execute workflow bash file.\n";
		print "2020/11/11  Added 'singularity' to container function.\n";
		print "2020/11/06  Updated help and daemon functionality.\n";
		print "2020/11/05  Added 'ls' function to insert file information to the database.\n";
		print "2020/10/09  Repeat functionality has been removed, since loop is bad...\n";
		print "2020/07/29  Able to run user defined command using 'EOS'.\n";
		print "2020/02/17  Temporary directory can be /tmp to reduce I/O traffic as much as possible.\n";
		print "2019/07/04  \$opt_i is specified with \$opt_o, it'll check if executing commands are necessary.\n";
		print "2019/05/23  \$opt_r was added for return specified value.\n";
		print "2019/05/15  \$opt_o was added for post-insert and unused batch routine removed.\n";
		print "2019/05/05  Set up 'output' for a command mode.\n";
		print "2019/04/08  'inputs' to pass inputs as variable array.\n";
		print "2019/04/04  Changed name of this program from 'daemon.pl' to 'moirai2.pl'.\n";
		print "2019/04/03  Array output functionality and command line functionality added.\n";
		print "2019/03/04  Stores run options in the SQLite database.\n";
		print "2019/02/07  'rm','rmdir','import' functions were added to batch routine.\n";
		print "2019/01/21  'mv' functionality added to move temporary files to designated locations.\n";
		print "2019/01/18  'process' functionality added to execute command from a control json.\n";
		print "2019/01/17  Subdivide triple database, revised execute flag to have instance in between.\n";
		print "2018/12/12  'singlethread' added for NCBI/BLAST query.\n";
		print "2018/12/10  Remove unnecessary files when completed.\n";
		print "2018/12/04  Added 'maxjob' and 'nolog' to speed up processed.\n";
		print "2018/11/27  Separating loading, selection, and execution and added 'maxjob'.\n";
		print "2018/11/19  Improving database updates by speed.\n";
		print "2018/11/17  Making daemon faster by collecting individual database accesses.\n";
		print "2018/11/16  Making updating/importing database faster by using improved rdf.pl.\n";
		print "2018/11/09  Added import function where user udpate databse through specified file(s).\n";
		print "2018/09/14  Changed to a ticket system.\n";
		print "2018/02/06  Added qsub functionality.\n";
		print "2018/02/01  Created to throw jobs registered in triple database.\n";
		print "\n";
	}
	exit(0);
}
sub help_check{
	print "\n";
	print "############################## HELP ##############################\n";
	print "\n";
	print "Usage: perl $program_name [Options] check";
	print "\n";
	print "Options: -i  Input query to assign in '\$sub->\$pred->\$obj' format.\n";
	print "         -o  Output query to assign in '\$sub->\$pred->\$obj' format.\n";
	print "\n";
	print "############################## Examples ##############################\n";
	print "\n";
	print "(1) perl $program_name -i '\$id->rawcount->\$count1,\$id->tagcount->\$count2' '\$count1==\$count2'\n";
	print "  - Check if \$count1 and \$count2 are same.\n";
	print "\n";
	print "(2) perl $program_name -i '\$id->rawcount->\$count1,\$id->tagcount->\$count2' -o '\$id->check->\$check' '\$count1==\$count2'\n";
	print "  - Check if \$count1 and \$count2 are same and same the result in '\$id->check->\$check'.\n";
	print "  - If there are same 'OK', if not 'ERROR'.\n";
	print "  - Differences will be saved under \$logdir/check/.\n";
	print "\n";
}
sub help_command{
	print "\n";
	print "############################## HELP ##############################\n";
	print "\n";
	print "Usage: perl $program_name [Options] command [ASSIGN ..] << 'EOS'\n";
	print "COMMAND ..\n";
	print "COMMAND2 ..\n";
	print "EOS\n";
	print "\n";
	print "     ASSIGN  Assign a MOIRAI2 variables with '\$VAR=VALUE' format.\n";
	print "    COMMAND  Bash command lines to execute.\n";
	print "        EOS  Assign command lines with Unix's heredoc.\n";
	print "\n";
	print "Options: -a  (A)ccess server and compute (default=local computer).\n";
	print "         -b  Specify (b)oolean options when running a command line (example -a:\$optionA,-b:\$optionB).\n\n";
	print "         -c  Use (c)ontainer image for execution [docker|singularity].\n";
	print "         -d  Triple (d)atabase directory (default='moirai').\n";
	print "         -E  Ignore STD(E)RR if specific regexp is found.\n";
	print "         -f  Record (f)ilestats[linecount/seqcount/md5/filesize/utime] of input/output files.\n";
	print "         -F  If specified output (f)ile is empty, record as error.\n";
	print "         -g  (G)rep string\n";
	print "         -G  Un(g)rep string when \n";
	print "         -h  Show (h)elp message.\n";
	print "         -H  Show update (h)istory.\n";
	print "         -i  (I)nput query for select from database in '\$sub->\$pred->\$obj' format.\n";
	print "         -l  Show (l)ogs from moirai.pl.\n";
	print "         -m  (M)ax number of jobs to throw (default='5').\n";
	print "         -o  (O)utput query for insert to database in '\$sub->\$pred->\$obj' format.\n";
	print "         -O  Ignore STD(O)UT if specific regexp is found.\n";
	print "         -p  (P)rint command lines instead of executing.\n";
	print "         -q  Use (q)sub or slurm for throwing jobs [qsub|slurm].\n";
	print "         -Q  (Q)sub/slurm options [qsub/sge/squeue/slurm].\n";
	print "         -r  Print (r)eturn value (in exec mode, stdout is default).\n";
	print "         -s  Loop (s)econd (default='10').\n";
	print "         -S  Implement/import (s)cript code to a command json file.\n";
	print "         -u  Run in (U)ser mode where input parameters are prompted.\n";
	print "\n";
	print "############################## Examples ##############################\n";
	print "\n";
	print "(1) perl $program_name -o 'root->input->\$output' command << 'EOS'\n";
	print "output=(`ls`)\n";
	print "EOS\n";
	print "\n";
	print "  - ls and store them in database with root->input->\$output format.\n";
	print "  - When you want an array, be sure to quote with ().\n";
	print "\n";
	print "(2) echo 'output=(`ls`)'|perl $program_name -o 'root->input->\$output' command\n";
	print "\n";
	print "  - It is same as example1, but without using 'EOS' notation.\n";
	print "\n";
	print "(3) perl $program_name -i 'A->input->\$input' -o 'A->output->\$output' command << 'EOS'\n";
	print "output=sort/\${input.basename}.txt\n";
	print "sort \$input > \$output\n";
	print "EOS\n";
	print "\n";
	print "  - Does sort on the \$input and creates a sorted file \$output\n";
	print "  - Query database with 'A->input->\$input' and store new triple 'A->output->\$output'.\n";
	print "\n";
}
sub help_daemon{
	print "\n";
	print "############################## HELP ##############################\n";
	print "\n";
	print "Program: Look for Other moirai2 databases under directory and run database once if it is updated.\n";
	print "\n";
	print "Usage: perl $program_name [Options] daemon DIR\n";
	print "\n";
	print "       DIR  Directories to look for.  Default is current directory.\n";
	print "\n";
	print "Options: -o  Log output directory (default='daemon').\n";
	print "         -r  Recursive search through a directory (default='0').\n";
	print "         -s  Loop second (default='10 sec').\n";
	print "\n";
}
sub help_exec{
	print "\n";
	print "############################## help_exec ##############################\n";
	print "\n";
	print "Program: Execute one line command.\n";
	print "\n";
	print "Usage: perl $program_name [Options] exec CMD ..\n";
	print "\n";
	print "       CMD  One line command like 'ls'.\n";
	print "\n";
	print "Options: -a  (A)ccess server and compute (default=local computer).\n";
	print "         -c  Use (c)ontainer image for execution [docker|singularity].\n";
	print "         -d  Triple (d)atabase directory (default='moirai').\n";
	print "         -f  Record (f)ilestats[linecount/seqcount/md5/filesize/utime] of input/output files.\n";
	print "         -F  If specified output (f)ile is empty, record as error.\n";
	print "         -g  (G)rep string\n";
	print "         -G  Un(g)rep string when \n";
	print "         -h  Show (h)elp message.\n";
	print "         -H  Show update (h)istory.\n";
	print "         -i  (I)nput query for select from database in '\$sub->\$pred->\$obj' format.\n";
	print "         -l  Show (l)ogs from moirai.pl.\n";
	print "         -m  (M)ax number of jobs to throw (default='5').\n";
	print "         -o  (O)utput query for insert to database in '\$sub->\$pred->\$obj' format.\n";
	print "         -p  (P)rint command lines instead of executing.\n";
	print "         -q  Use (q)sub or slurm for throwing jobs [qsub|slurm].\n";
	print "         -Q  (Q)sub/slurm options [qsub/sge/squeue/slurm].\n";
	print "         -r  Print (r)eturn value (in exec mode, stdout is default).\n";
	print "         -s  Loop (s)econd (default='10').\n";
	print "         -S  Implement/import (s)cript code to a command json file.\n";
	print "         -u  Run in (U)ser mode where input parameters are prompted.\n";
	print "\n";
	print "Note: Log file (including execution time, STDOUT, STDERR) stored under moirai/log/YYYYMMDD/ directory\n";
	print "      Error files will be stored under moirai/log/error/ directory\n";
	print "\n";
	print "Example:\n";
	print "(1) perl $program_name exec uname\n";
	print "  - Return uname result\n";
	print "\n";
	print "(2) perl $program_name exec 'ls | cut -c1-3 | sort | uniq | wc -l'\n";
	print "  - Execute piped command line using single quotes\n";
	print "\n";
	print "(3) perl $program_name exec 'ls > output.txt'\n";
	print "  - Write file lists to output files\n";
	print "\n";
	print "(4) perl $program_name -q sge exec ls -lt\n";
	print "  - List files under current directory using Sun Grid Engine (SGE) qsub\n";
	print "\n";
	print "(5) perl $program_name -a ah3q\@dgt-ac4 exec echo hello world\n";
	print "  - Returns 'hello world' at dgt-ac4 server\n";
	print "\n";
	print "(6) perl $program_name -q slurm -a ah3q\@dgt-ac4 exec ls -lt /work/ah3q/\n";
	print "  - List files under /work/ah3q at dgt-ac4 server using slurm queing system\n";
	print "\n";
	print "(7) perl $program_name -o '\$output' exec 'output=(`ls`)'\n";
	print "  - List directory and store results in \$output array\n";
	print "\n";
}
sub help_extract{
	print "\n";
	print "############################## HELP ##############################\n";
	print "\n";
	print "Program: Extracts script and bash files from URL and save them to a directory.\n";
	print "\n";
	print "Usage: perl $program_name [Options] script JSON\n";
	print "\n";
	print "       JSON  URL or path to a command json file (from https://moirai2.github.io/command/).\n";
	print "\n";
	print "Options: -o  Output directory (default='out').\n";
	print "\n";
}
sub help_html{
	print "\n";
	print "############################## HELP ##############################\n";
	print "\n";
	print "Program: Print out a HTML representation of the database.\n";
	print "\n";
	print "Usage: perl $program_name [Options] html > HTML\n";
	print "\n";
}
sub help_progress{
	print "\n";
	print "############################## help_progress ##############################\n";
	print "\n";
	print "Program: Print out status in json format for browser interface.\n";
	print "\n";
	print "Usage: perl $program_name [Options] progress > JSON\n";
	print "\n";
}
sub help_ls{
	print "\n";
	print "############################## HELP ##############################\n";
	print "\n";
	print "Program: List files/directories and store path information to DB.\n";
	print "\n";
	print "Usage: perl $program_name [Options] ls DIR DIR2 ..\n";
	print "\n";
	print "        DIR  Directory to search for (if not specified, DIR='.').\n";
	print "\n";
	print "Options: -d  RDF database directory (default='moirai').\n";
	print "         -g  grep specific string\n";
	print "         -G  ungrep specific string\n";
	print "         -i  Input query for select in '\$sub->\$pred->\$obj' format.\n";
	print "         -l  Print out logs instead of importing results to the database.\n";
	print "         -o  Output query for insert in '\$sub->\$pred->\$obj' format.\n";
	print "         -r  Recursive search (default=0)\n";
	print "\n";
	print "Variables:\n";
	print "  \$file        Path to a file\n";
	print "  \$path        Full path to a file\n";
	print "  \$directory   dirname\n";
	print "  \$filename    filename\n";
	print "  \$basename    Without suffix\n";
	print "  \$suffix      suffix without period\n";
	print "  \$dirX        X=int directory name separated by '/'\n";
	print "  \$baseX       X=int filename sepsrsted by alphabet/number\n";
	print "  \$linecount   Print line count of a file (Can take care of gzip and bzip2).\n";
	print "  \$seqcount    Print sequence count of a FASTA/FASTQ files.\n";
	print "  \$filesize    Print size of a file.\n";
	print "  \$md5         Print MD5 of a file.\n";
	print "  \$timestamp   Print time stamp of a file.\n";
	print "  \$owner       Print owner of a file.\n";
	print "  \$group       Print group of a file.\n";
	print "  \$permission  Print permission of a file.\n";
	print "\n";
	print "Note:\n";
	print " - When -i option is used, search will be canceled.\n";
	print " - Use \$file variable for -i option, when specifying a file path.\n";
	print "\n";
	print "############################## Examples ##############################\n";
	print "\n";
	print "(1) perl $program_name -r 0 -g A -G B -o '\$basename->id->\$path' ls DIR DIR2 ..\n";
	print "  - List files under DIR and DIR2 with 0 recursion and filename with A and filename without B.\n";
	print "\n";
	print "(2) perl $program_name -i 'root->input->\$file->' -o '\$basename->id->\$path' ls\n";
	print "  - Go look for file in the database and handle.\n";
	print "\n";
}
############################## MAIN ##############################
my $commands={};
if(defined($opt_h)&&$ARGV[0]=~/\.json$/){printCommand($ARGV[0],$commands);exit(0);}
if(defined($opt_h)&&$ARGV[0]=~/\.(ba)?sh$/){printWorkflow($ARGV[0],$commands);exit(0);}
if(defined($opt_h)&&scalar(@ARGV)>0&&$ARGV[0]eq"check"){help_check();exit(0);}
if(defined($opt_h)&&scalar(@ARGV)>0&&$ARGV[0]eq"command"){help_command();exit(0);}
if(defined($opt_h)&&scalar(@ARGV)>0&&$ARGV[0]eq"daemon"){help_daemon();exit(0);}
if(defined($opt_h)&&scalar(@ARGV)>0&&$ARGV[0]eq"extract"){help_extract();exit(0);}
if(defined($opt_h)&&scalar(@ARGV)>0&&$ARGV[0]eq"html"){help_html();exit(0);}
if(defined($opt_h)&&scalar(@ARGV)>0&&$ARGV[0]eq"ls"){help_ls();exit(0);}
if(defined($opt_h)&&scalar(@ARGV)>0&&$ARGV[0]eq"progress"){help_progress();exit(0);}
if(defined($opt_h)&&scalar(@ARGV)>0&&$ARGV[0]eq"exec"){help_exec();exit(0);}
if(defined($opt_h)||defined($opt_H)||scalar(@ARGV)==0){help();}
my $moiraidir=(defined($opt_d))?$opt_d:"moirai";
if(defined($opt_q)){
	if($opt_q eq "qsub"){$opt_q="sge";}
	elsif($opt_q eq "squeue"){$opt_q="slurm";}
}
checkMoiraiDirectory($moiraidir);
if($moiraidir=~/^(.+)\/$/){$moiraidir=$1;}
my $rootdir=absolutePath(".");
my $basename=basename($moiraidir);
my $bindir="$moiraidir/bin";
my $dbdir="$moiraidir/db";
my $logdir="$moiraidir/log";
my $jsondir="$moiraidir/json";
my $ctrldir="$moiraidir/ctrl";

my $checkdir="$logdir/check";
my $errordir="$logdir/error";

my $insertdir="$ctrldir/insert";
my $processdir="$ctrldir/process";
my $submitdir="$ctrldir/submit";
my $jobdir="$ctrldir/job";

my $home=`echo \$HOME`;chomp($home);
my $exportpath="$rootdir/$moiraidir/bin:$rootdir/bin:$home/bin:\$PATH";
my $sleeptime=defined($opt_s)?$opt_s:60;
my $maxjob=defined($opt_m)?$opt_m:5;
if($ARGV[0] eq "daemon"){shift(@ARGV);daemon(@ARGV);exit(0);}
if($ARGV[0] eq "extract"){shift(@ARGV);extract(@ARGV);exit(0);}
if($ARGV[0] eq "html"){shift(@ARGV);html(@ARGV);exit(0);}
if($ARGV[0] eq "progress"){shift(@ARGV);progress(@ARGV);exit(0);}
if($ARGV[0] eq "test"){shift(@ARGV);test();exit(0);}
mkdir($moiraidir);chmod(0777,$moiraidir);
mkdir($dbdir);chmod(0777,$dbdir);
mkdir($logdir);chmod(0777,$logdir);
mkdir($errordir);chmod(0777,$errordir);
mkdir($jsondir);chmod(0777,$jsondir);
mkdir($ctrldir);chmod(0777,$ctrldir);
mkdir($checkdir);chmod(0777,$checkdir);
mkdir($bindir);chmod(0777,$bindir);
mkdir($processdir);chmod(0777,$processdir);
mkdir($jobdir);chmod(0777,$jobdir);
mkdir($insertdir);chmod(0777,$insertdir);
mkdir($submitdir);chmod(0777,$submitdir);
if($ARGV[0] eq "check"){shift(@ARGV);check(@ARGV);exit(0);}
if($ARGV[0] eq "ls"){shift(@ARGV);ls(@ARGV);exit(0);}
my $cmdpaths={};
my $md5cmd=which('md5sum',$cmdpaths);
if(!defined($md5cmd)){$md5cmd=which('md5',$cmdpaths);}
#{moirai/json/j20210824121358.json}=>	[0]=>	{execid}=>	"e20210824170442"
my $executes={};
#{"e20210824170442"}=>{workdir}=>"moirai/e20210824170442"
#{"e20210824170442"}=>{lastupdate}=>1629792288
my $processes=reloadJobsRunning();
#just in case jobs are completed while moirai2.pl was not running by termination
controlWorkflow($executes,$processes);
if(getNumberOfJobsRunning()>0){
	print STDERR "There are jobs remaining in ctrl/bash directory.\n";
	print STDERR "Do you want to delete these jobs [y/n]? ";
	my $prompt=<STDIN>;
	chomp($prompt);
	if($prompt eq "y"||$prompt eq "yes"||$prompt eq "Y"||$prompt eq "YES"){
		system("rm $processdir/*");
		$processes={};
	}
}
if($ARGV[0] eq "automate"){automate();exit(0);}
##### handle inputs and outputs #####
my $queryResults;
my $queryKeys;
my $insertKeys=[];
my $inputKeys=[];
my $outputKeys=[];
my $cmdurl=shift(@ARGV);
my ($arguments,$userdefined)=handleArguments(@ARGV);
if(defined($opt_i)){
	if(checkInputOutput($opt_i)){
		my $query=$opt_i;
		while(my($key,$val)=each(%{$userdefined})){$query=~s/\$$key/$val/g;}
		$queryKeys=handleInputOutput($query);
		$queryResults=getQueryResults($dbdir,$query);
	}else{
		$inputKeys=handleValues($opt_i);
	}
}
if(!defined($queryResults)){$queryResults=[[],[{}]];}
if(scalar(keys(%{$userdefined}))>0){
	my $hash={};
	foreach my $key(@{$inputKeys}){$hash->{$key}=1;}
	while(my($key,$val)=each(%{$userdefined})){
		if(!exists($hash->{$key})){push(@{$inputKeys},$key);}
	}
}
if(defined($opt_o)){
	if(checkInputOutput($opt_o)){
		my $query=$opt_o;
		while(my($key,$val)=each(%{$userdefined})){$query=~s/\$$key/$val/g;}
		$insertKeys=handleInputOutput($query);
		if(defined($queryKeys)){removeUnnecessaryExecutes($queryResults,$query);}
	}else{
		$outputKeys=handleValues($opt_o);
	}
}
if(defined($opt_r)){
	my $array=handleValues($opt_r);
	foreach my $value(@{$array}){if(!existsArray($outputKeys,$value)){push(@{$outputKeys},$value);}}
}
if(defined($opt_l)){printRows($queryResults->[0],$queryResults->[1]);}
##### handle commmand #####
my @execids;
my $cmdLine;
if($cmdurl eq "command"){
	my @lines=();
	while(<STDIN>){
		chomp;
		push(@lines,$_);
		if(defined($cmdLine)){$cmdLine.=";$_"}
		else{$cmdLine.=$_;}
	}
	my ($inputs,$outputs)=setupInputOutput($insertKeys,$queryResults,$inputKeys,$outputKeys);
	my $scripts=handleArray($opt_S);
	$cmdurl=createJson($moiraidir,$inputs,$outputs,$scripts,@lines);
}elsif($cmdurl eq "exec"){
	$cmdLine=join(" ",@{$arguments});
	if(!defined($opt_i)&&!defined($opt_o)&&!defined($opt_r)){
		($cmdLine,$inputKeys,$outputKeys)=getInputsOutputsFromCommand($cmdLine,$userdefined);
	}
	$arguments=[];
	my ($inputs,$outputs)=setupInputOutput($insertKeys,$queryResults,$inputKeys,$outputKeys);
	my $scripts=handleArray($opt_S);
	$cmdurl=createJson($moiraidir,$inputs,$outputs,$scripts,$cmdLine);
	if(!defined($opt_r)){$opt_r="\$stdout";}
	$sleeptime=1;
}
if(defined($cmdurl)){
	@execids=commandProcess($cmdurl,$commands,$queryResults,$userdefined,$queryKeys,$insertKeys,$cmdLine,@{$arguments});
}
##### process #####
my @execurls=();
while(true){
	controlWorkflow($executes,$processes);
	if(getNumberOfJobsRemaining($executes)<$maxjob){loadExecutes($commands,$executes,\@execurls);}
	my $jobs_running=getNumberOfJobsRunning();
	if($jobs_running<$maxjob){mainProcess(\@execurls,$commands,$executes,$processes,$maxjob-$jobs_running);}
	$jobs_running=getNumberOfJobsRunning();
	if(getNumberOfJobsRemaining($executes)==0&&$jobs_running==0){controlWorkflow($executes,$processes);last;}
	else{sleep($sleeptime);}
}
if(!defined($cmdurl)){
	# command URL not defined
}elsif(defined($opt_o)){
	# Output are defined, so don't print return
}elsif(exists($commands->{$cmdurl}->{$urls->{"daemon/return"}})){
	my $returnvalue=$commands->{$cmdurl}->{$urls->{"daemon/return"}};
	my $match="$cmdurl#$returnvalue";
	if($returnvalue eq "stdout"){$match="stdout";}
	elsif($returnvalue eq "stderr"){$match="stderr";}
	foreach my $execid(sort{$a cmp $b}@execids){returnResult($execid,$match);}
}
############################## absolutePath ##############################
sub absolutePath {
	my $path=shift();
	my $directory=dirname($path);
	my $filename=basename($path);
	my $path=Cwd::abs_path($directory)."/$filename";
	$path=~s/\/\.\//\//g;
	$path=~s/\/\.$//g;
	return $path
}
############################## appendText ##############################
sub appendText{
	my $line=shift();
	my $file=shift();
	open(OUT,">>$file");
	print OUT "$line\n";
	close(OUT);
}
############################## assignCommand ##############################
sub assignCommand{
	my $command=shift();
	my $userdefined=shift();
	my $queryResults=shift();
	my @inputs=@{$command->{$urls->{"daemon/input"}}};
	my @outputs=@{$command->{$urls->{"daemon/output"}}};
	my $keys={};
	foreach my $key(@{$queryResults->[0]}){$keys->{$key}++;}
	foreach my $input(@inputs){
		if(exists($userdefined->{$input})){next;}
		if(exists($keys->{$input})){$userdefined->{$input}="\$$input";next;}
		if(defined($opt_u)){promptCommandInput($command,$userdefined,$input);}
		elsif(exists($command->{"default"}->{$input})){$userdefined->{$input}=$command->{"default"}->{$input};}
	}
}
############################## automate ##############################
sub automate{
	my @files=getFiles("$moiraidir/automate");
	if(scalar(@files)==0){return 0;}
	foreach my $file(sort{$a cmp $b}@files){
		my $basename=basename($file);
		my $command=loadCommandFromURL($file);
		my ($writer,$bashFile)=tempfile("bashXXXXXXXXXX",DIR=>"/tmp/",SUFFIX=>".sh");
		my $basename=basename($bashFile,".sh");
		my $stdout=defined($opt_O)?$opt_O:"$logdir/$basename.stdout";
		my $stderr=defined($opt_E)?$opt_E:"$logdir/$basename.stderr";
		my $qjob=$command->{$urls->{"daemon/qjob"}};
		my $qjobopt=$command->{$urls->{"daemon/qjob/opt"}};
		if(defined($opt_q)){$qjob=$opt_q;}
		if(defined($opt_Q)){$qjobopt=$opt_Q;}
		if($qjob eq "sge"){
			print $writer "#\$ -e $stderr\n";
			print $writer "#\$ -o $stdout\n";
		}
		print $writer "cd $rootdir\n";
		my @lines=@{$command->{$urls->{"daemon/bash"}}};
		foreach my $line(@lines){print $writer "$line\n";}
		if(!defined($opt_O)){
			print $writer "if [ ! -s $stdout ];then\n";
			print $writer "rm -f $stdout\n";
			print $writer "fi\n";
		}
		if(!defined($opt_E)){
			print $writer "if [ ! -s $stderr ];then\n";
			print $writer "rm -f $stderr\n";
			print $writer "fi\n";
		}
		print $writer "rm -f $bashFile\n";
		close($writer);
		throwBashJob($bashFile,$qjob,$qjobopt,$stdout,$stderr);
	}
}
############################## basenames ##############################
sub basenames{
	my $path=shift();
	my $directory=dirname($path);
	my $filename=basename($path);
	my $basename;
	my $suffix;
	my $hash={};
	if($filename=~/^(.+)\.([^\.]+)$/){$basename=$1;$suffix=$2;}
	else{$basename=$filename;}
	$hash->{"path"}="$directory/$filename";
	$hash->{"file"}="$directory/$filename";
	$hash->{"directory"}=$directory;
	$hash->{"filename"}=$filename;
	$hash->{"basename"}=$basename;
	if(defined($suffix)){$hash->{"suffix"}=$suffix;}
	my @dirs=split(/\//,$directory);
	if($dirs[0] eq ""){shift(@dirs);}
	for(my $i=0;$i<scalar(@dirs);$i++){$hash->{"dir$i"}=$dirs[$i];}
	my @bases=split(/[\W_]+/,$basename);
	for(my $i=0;$i<scalar(@bases);$i++){$hash->{"base$i"}=$bases[$i];}
	return $hash;
}
############################## bashCommand ##############################
sub bashCommand{
	my $command=shift();
	my $vars=shift();
	my $bashFiles=shift();
	my $execid=$vars->{"execid"};
	my $url=$command->{$urls->{"daemon/command"}};
	my $options=$command->{"options"};
	my $workdir="$rootdir/$moiraidir/$execid";
	my $rootdir=$vars->{"rootdir"};
	my $homedir=$vars->{"homedir"};
	my $tmpdir="$rootdir/".$vars->{"tmpdir"};
	my $bashsrc=$vars->{"bashsrc"};
	my $bashfile=$vars->{"bashfile"};
	my $bashscp=$vars->{"bashscp"};
	my $stderrfile=$vars->{"stderrfile"};
	my $stdoutfile=$vars->{"stdoutfile"};
	my $container=$command->{$urls->{"daemon/container"}};
	my $server=$command->{$urls->{"daemon/server"}};
	my $tmpExists=existsString("\\\$tmpdir",$command->{"bashCode"})||(scalar(@{$command->{"output"}})>0);
	open(OUT,">$bashsrc");
	print OUT "#!/bin/sh\n";
	if(exists($command->{"script"})){print OUT "export PATH=$workdir/bin:$exportpath\n";}
	else{print OUT "export PATH=$exportpath\n";}
	my @systemvars=("cmdurl","execid","rootdir","workdir");
	my @unusedvars=("bashfile","bashsrc","bashscp","server","srcdir","stderrfile","stdoutfile","username");
	my @outputvars=(@{$command->{"output"}});
	if($tmpExists){push(@systemvars,"tmpdir");}
	else{push(@unusedvars,"tmpdir");}
	foreach my $var(@systemvars){print OUT "$var=\"".$vars->{$var}."\"\n";}
	my @keys=();
	foreach my $key(sort{$a cmp $b}keys(%{$vars})){
		my $break=0;
		foreach my $var(@systemvars){if($var eq $key){$break=1;last;}}
		foreach my $var(@unusedvars){if($var eq $key){$break=1;last;}}
		foreach my $var(@outputvars){if($var eq $key){$break=1;last;}}
		if($break){next;}
		push(@keys,$key);
	}
	print OUT "cd \$rootdir\n";
	foreach my $key(@keys){
		my $value=$vars->{$key};
		if(exists($options->{$key})){
			if($value eq ""){next;}
			if($value eq "0"){next;}
			if($value eq "F"){next;}
			if($value=~/false/i){next;}
			$value=$options->{$key};
			print OUT "$key=\"$value\"\n";
		}else{
			if(ref($value)eq"ARRAY"){print OUT "$key=(\"".join("\" \"",@{$value})."\")\n";}
			else{print OUT "$key=\"$value\"\n";}
		}
	}
	my $basenames={};
	foreach my $key(@keys){
		my $value=$vars->{$key};
		if(ref($value)eq"ARRAY"){next;}
		elsif($value=~/[\.\/]/){
			my $hash=basenames($value);
			while(my ($k,$v)=each(%{$hash})){$basenames->{"$key.$k"}=$v;}
		}
	}
	print OUT "touch \$workdir/status.txt\n";
	print OUT "touch \$workdir/log.txt\n";
	print OUT "function status() { echo \"\$1\t\"`date +\%s` >> \$workdir/status.txt ; }\n";
	print OUT "function record() { echo \"\$1\t\$2\" >> \$workdir/log.txt ; }\n";
	my @scriptfiles=();
	if(exists($command->{"script"})){
		print OUT "mkdir -p \$workdir/bin\n";
		foreach my $name (@{$command->{"script"}}){
			my $path="\$workdir/bin/$name";
			push(@scriptfiles,$name);
			print OUT "cat<<EOF>$path\n";
			foreach my $line(scriptCodeForBash(@{$command->{$name}})){print OUT "$line\n";}
			print OUT "EOF\n";
			print OUT "chmod 755 $path\n";
		}
	}
	if($tmpExists){
		print OUT "mkdir -p /tmp/\$execid\n";
		print OUT "ln -s /tmp/\$execid \$workdir/tmp\n";
	}
	my @unzips=();
	if(exists($command->{$urls->{"daemon/unzip"}})){
		foreach my $key(@{$command->{$urls->{"daemon/unzip"}}}){
			if(exists($vars->{$key})){
				my @values=(ref($vars->{$key})eq"ARRAY")?@{$vars->{$key}}:($vars->{$key});
				foreach my $value(@values){
					if($value=~/^(.+)\.bz(ip)?2$/){
						my $basename=basename($1);
						print OUT "$key=\$workdir/$basename\n";
						print OUT "bzip2 -cd $value>\$$key\n";
						push(@unzips,"\$workdir/$basename");
					}elsif($value=~/^(.+)\.gz(ip)?$/){
						my $basename=basename($1);
						print OUT "$key=\$workdir/$basename\n";
						print OUT "gzip -cd $value>\$$key\n";
						push(@unzips,"\$workdir/$basename");
					}
				}
			}
		}
	}
	if(exists($command->{$urls->{"daemon/error/file/empty"}})){
		my $hash=$command->{$urls->{"daemon/error/file/empty"}};
		my $index=0;
		foreach my $input(@{$command->{"input"}}){
			if(!exists($hash->{$input})){next;}
			print OUT "if [[ \"\$(declare -p $input)\" =~ \"declare -a\" ]]; then\n";
			print OUT "for in in \${$input"."[\@]} ; do\n";
			print OUT "if [ ! -s \$in ]; then\n";
			print OUT "echo 'Empty input: \$in' 1>&2\n";
			print OUT "fi\n";
			print OUT "done\n";
			print OUT "else\n";
			print OUT "if [ ! -s \$$input ]; then\n";
			print OUT "echo \"Empty input: \$$input\" 1>&2\n";
			print OUT "fi\n";
			print OUT "fi\n";
			$index++;
		}
	}
	if(scalar(@{$command->{"output"}})>0){
		my $count=0;
		foreach my $output(@{$command->{"output"}}){
			print OUT "$output=\$tmpdir/output$count\n";
			$count++;
		}
	}
	print OUT "status start\n";
	print OUT "########## command ##########\n";
	foreach my $line(@{$command->{"bashCode"}}){
		my $temp=$line;
		if($temp=~/\$\{.+\}/){while(my ($k,$v)=each(%{$basenames})){$temp=~s/\$\{$k\}/$v/g;}}
		print OUT "$temp\n";
	}
	print OUT "#############################\n";
	print OUT "status end\n";
	foreach my $output(@{$command->{"output"}}){
		if(exists($vars->{$output})&&$output ne $vars->{$output}){
			my $value=$vars->{$output};
			print OUT "mv \$$output $value\n";
			print OUT "$output=$value\n";
		}
	}
	if(exists($command->{$urls->{"daemon/file/linecount"}})){
		foreach my $key(@{$command->{$urls->{"daemon/file/linecount"}}}){
			print OUT "if [[ \"\$(declare -p $key)\" =~ \"declare -a\" ]]; then\n";
			print OUT "for out in \${$key"."[\@]} ; do\n";
			print OUT "perl rdf.pl linecount \$out\n";
			print OUT "done\n";
			print OUT "else\n";
			print OUT "perl rdf.pl linecount \$$key\n";
			print OUT "fi\n";
		}
	}
	if(exists($command->{$urls->{"daemon/file/seqcount"}})){
		foreach my $key(@{$command->{$urls->{"daemon/file/seqcount"}}}){
			print OUT "if [[ \"\$(declare -p $key)\" =~ \"declare -a\" ]]; then\n";
			print OUT "for out in \${$key"."[\@]} ; do\n";
			print OUT "perl rdf.pl seqcount \$out\n";
			print OUT "done\n";
			print OUT "else\n";
			print OUT "perl rdf.pl seqcount \$$key\n";
			print OUT "fi\n";
		}
	}
	if(exists($command->{$urls->{"daemon/file/md5"}})){
		foreach my $key(@{$command->{$urls->{"daemon/file/md5"}}}){
			print OUT "if [[ \"\$(declare -p $key)\" =~ \"declare -a\" ]]; then\n";
			print OUT "for out in \${$key"."[\@]} ; do\n";
			print OUT "perl rdf.pl md5 \$out\n";
			print OUT "done\n";
			print OUT "else\n";
			print OUT "perl rdf.pl md5 \$$key\n";
			print OUT "fi\n";
		}
	}
	if(exists($command->{$urls->{"daemon/file/filesize"}})){
		foreach my $key(@{$command->{$urls->{"daemon/file/filesize"}}}){
			print OUT "if [[ \"\$(declare -p $key)\" =~ \"declare -a\" ]]; then\n";
			print OUT "for out in \${$key"."[\@]} ; do\n";
			print OUT "perl rdf.pl filesize \$out\n";
			print OUT "done\n";
			print OUT "else\n";
			print OUT "perl rdf.pl seqcount \$$key\n";
			print OUT "fi\n";
		}
	}
	if(exists($command->{$urls->{"daemon/filestats"}})){
		foreach my $key(@{$command->{$urls->{"daemon/filestats"}}}){
			print OUT "if [[ \"\$(declare -p $key)\" =~ \"declare -a\" ]]; then\n";
			print OUT "for out in \${$key"."[\@]} ; do\n";
			print OUT "perl rdf.pl filestats \$out\n";
			print OUT "done\n";
			print OUT "else\n";
			print OUT "perl rdf.pl filestats \$$key\n";
			print OUT "fi\n";
		}
	}
	my $inserts={};
	if(exists($command->{"insertKeys"})&&scalar(@{$command->{"insertKeys"}})>0){
		foreach my $insert(@{$command->{"insertKeys"}}){
			my $found=0;
			my $line=join("->",@{$insert});
			foreach my $output(@{$command->{"output"}}){
				if($line=~/\$$output/){push(@{$inserts->{$output}},$insert);$found=1;last;}
			}
			if($found==0){push(@{$inserts->{""}},$insert);}
		}
	}
	if(exists($command->{"output"})&&scalar(@{$command->{"output"}})>0){
		foreach my $output(@{$command->{"output"}}){
			print OUT "if [[ \"\$(declare -p $output)\" =~ \"declare -a\" ]]; then\n";
			print OUT "for out in \${$output"."[\@]} ; do\n";
			print OUT "record \"\$cmdurl#$output\" \"\$out\"\n";
			if(exists($inserts->{$output})){
				foreach my $row(@{$inserts->{$output}}){
					my $line=join("->",@{$row});
					$line=~s/\$$output/\$out/g;
					print OUT "echo \"$line\"\n";
				}
			}
			print OUT "done\n";
			print OUT "else\n";
			print OUT "record \"\$cmdurl#$output\" \"\$$output\"\n";
			if(exists($inserts->{$output})){
				foreach my $row(@{$inserts->{$output}}){print OUT "echo \"".join("->",@{$row})."\"\n";}
			}
			print OUT "fi\n";
		}
	}
	if(exists($inserts->{""})){foreach my $row(@{$inserts->{""}}){print OUT "echo \"".join("->",@{$row})."\"\n";}}
	if(scalar(@unzips)>0){
		foreach my $unzip(@unzips){print OUT "rm $unzip\n";}
	}
	if($tmpExists){
		print OUT "rm \$workdir/tmp\n";
		print OUT "if [ -z \"\$(ls -A /tmp/\$execid)\" ]; then\n";
	  	print OUT "rmdir /tmp/\$execid\n";
		print OUT "else\n";
		print OUT "mv /tmp/\$execid \$workdir/tmp\n";
		print OUT "fi\n";
	}
	print OUT "status=completed\n";
	if(exists($command->{$urls->{"daemon/error/file/empty"}})){
		my $index=0;
		my $hash=$command->{$urls->{"daemon/error/file/empty"}};
		foreach my $output(@{$command->{"output"}}){
			if(!exists($hash->{$output})){next;}
			print OUT "if [[ \"\$(declare -p $output)\" =~ \"declare -a\" ]]; then\n";
			print OUT "for out in \${$output"."[\@]} ; do\n";
			print OUT "if [ ! -s \$out ]; then\n";
			print OUT "echo 'Empty output: \$out' 1>&2\n";
			print OUT "status=error\n";
			print OUT "fi\n";
			print OUT "done\n";
			print OUT "else\n";
			print OUT "if [ ! -s \$$output ]; then\n";
			print OUT "echo \"Empty output: \$$output\" 1>&2\n";
			print OUT "status=error\n";
			print OUT "fi\n";
			print OUT "fi\n";
			$index++;
		}
	}
	if(exists($command->{$urls->{"daemon/return"}})&&$command->{$urls->{"daemon/return"}}eq"stdout"){}
	elsif(exists($command->{$urls->{"daemon/error/stdout/ignore"}})){
		my $lines=$command->{$urls->{"daemon/error/stdout/ignore"}};
		foreach my $line(@{$lines}){
			print OUT "if [ \"\$(grep '$line' \$workdir/stdout.txt)\" != \"\" ]; then\n";
			print OUT "status=error\n";
			print OUT "fi\n";
		}
	}
	if(exists($command->{$urls->{"daemon/error/stderr/ignore"}})){
		my $lines=$command->{$urls->{"daemon/error/stderr/ignore"}};
		foreach my $line(@{$lines}){
			print OUT "if [ \"\$(grep '$line' \$workdir/stderr.txt)\" != \"\" ]; then\n";
			print OUT "status=error\n";
			print OUT "fi\n";
		}
	}else{
			print OUT "if [ -s \$workdir/stderr.txt ]; then\n";
			print OUT "status=error\n";
			print OUT "fi\n";
	}
	print OUT "status \$status\n";
	close(OUT);
}
############################## check ##############################
sub check{
	my @checks=@_;
	if(!defined($opt_i)){print STDERR "Please use option '-i' to assign triple query\n";exit(1);}
	elsif(!defined(checkInputOutput($opt_i))){return;}
	my $query=$opt_i;
	while(my($key,$val)=each(%{$userdefined})){$query=~s/\$$key/$val/g;}
	my $queryResults=getQueryResults($dbdir,$query);
	if(defined($opt_o)){
		checkInputOutput($opt_o);
		my $insertKeys=handleInputOutput($opt_o);
		removeUnnecessaryExecutes($queryResults,$opt_o);
		my ($writer,$temp)=tempfile(UNLINK=>1);
		my ($writer2,$temp2)=tempfile();
		foreach my $result(@{$queryResults->[1]}){
			my @lines=checkEval($result,$opt_i,@checks);
			foreach my $line(@lines){print $writer2 "$line\n";}
			my $check=(scalar(@lines)>0)?"ERROR":"OK";
			foreach my $insert(@{$insertKeys}){
				my $line=join("\t",@{$insert});
				while(my($key,$val)=each(%{$result})){$line=~s/\$$key/$val/g;}
				$line=~s/\$check/$check/g;
				print $writer "$line\n";
			}
		}
		close($writer2);
		close($writer);
		system("perl $prgdir/rdf.pl -q -d $moiraidir import < $temp");
		if(-s $temp2){
			my $id="c".getDatetime();
			my $file="$checkdir/$id.txt";
			while(existsLogFile($file)){
				sleep(1);
				$id="e".getDatetime();
				$file="$checkdir/$id.txt";
			}
			system("mv $temp2 $file");
		}
	}else{
		foreach my $result(@{$queryResults->[1]}){
			my @lines=checkEval($result,$opt_i,@checks);
			if(scalar(@lines)>0){foreach my $line(@lines){print "$line\n";}}
		}
	}
}
############################## checkArray ##############################
sub checkArray{
	my $val=shift();
	my $index=shift();
	my $array=shift();
	my $hash=shift();
	if(defined($hash)){if(!exists($hash->{$val})){return 1;}$val=$hash->{$val};}
	foreach my $t(@{$array}){if($t->[$index] eq $val){return 1;}}
}
############################## checkCtrlDirectory ##############################
sub checkCtrlDirectory{
	my $directory=shift();
	my @files=listFiles("txt","$directory/ctrl/submit");
	if(scalar(@files)>0){return 1;}
	@files=listFiles("txt","$directory/ctrl/insert");
	if(scalar(@files)>0){return 1;}
	return;
}
############################## checkEval ##############################
sub checkEval{
	my @checks=@_;
	my $result=shift(@checks);
	my $input=shift(@checks);
	my @lines=();
	foreach my $check(@checks){
		my $statement=$check;
		foreach my $key(keys(%{$result})){
			my $val=$result->{$key};
			$statement=~s/\$$key/$val/g;
		}
		if(!eval($statement)){
			my $input=$opt_i;
			foreach my $key(keys(%{$result})){
				my $val=$result->{$key};
				$input=~s/\$$key/$val/g;
			}
			push(@lines,"ERROR($statement) $input");
		}
	}
	return @lines;
}
############################## checkInputOutput ##############################
sub checkInputOutput{
	my $queries=shift();
	my $triple;
	foreach my $query(split(/,/,$queries)){
		my @tokens=split(/->/,$query);
		if(scalar(@tokens)==1){
		}elsif(scalar(@tokens)==3){
			my $empty=0;
			$triple=1;
			foreach my $token(@tokens){if($token eq ""){$empty=1;last;}}
			if($empty==1){
				print STDERR "ERROR: '$query' has empty token.\n";
				print STDERR "ERROR: Use single quote '\$a->b->\$c' instead of double quote \"\$a->b->\$c\".\n";
				print STDERR "ERROR: Or escape '\$' with '\\' sign \"\\\$a->b->\\\$c\".\n";
				exit(1);
			}
		}
	}
	return $triple;
}
############################## checkMoiraiDirectory ##############################
sub checkMoiraiDirectory{
	my $directory=shift();
	if($directory=~/\.\./){
		print STDERR "ERROR: Please don't use '..' for moirai directory\n";
		exit();
	}elsif($directory=~/^\.$/){
		print STDERR "ERROR: Please don't use '.' for moirai directory\n";
		exit();
	}elsif($directory=~/^\//){
		print STDERR "ERROR: moirai directory have to be relative to a root directory\n";
		exit();
	}
}
############################## checkProcessStatus ##############################
sub checkProcessStatus{
	my $process=shift();
	my $workdir=$process->{$urls->{"daemon/workdir"}};
	my $lastUpdate=$process->{$urls->{"daemon/process/lastupdate"}};
	my $lastStatus=$process->{$urls->{"daemon/execute"}};
	my $statusfile="$workdir/status.txt";
	my $timestamp=checkTimestamp($statusfile);
	if(!defined($timestamp)){return;}
	if(!defined($lastUpdate)||$timestamp>$lastUpdate){
		$process->{$urls->{"daemon/process/lastupdate"}}=$timestamp;
		my $reader=openFile($statusfile);
		my $currentStatus;
		while(<$reader>){
			chomp;
			my ($key,$val)=split(/\t/);
			$currentStatus=$key;
		}
		close($reader);
		if($currentStatus eq $lastStatus){return;}
		$process->{$urls->{"daemon/execute"}}=$currentStatus;
		return $currentStatus;
	}else{
		return;
	}
}
############################## checkFileIsEmpty ##############################
sub checkFileIsEmpty {
	my $path=shift();
	if($path=~/^(.+\@.+)\:(.+)$/){
		my $size=`ssh $1 'perl -e \"my \@array=stat(\\\$ARGV[0]);print \\\$array[7]\" $2'`;
		chomp($size);
		return ($size==0);
	}else{
		return (-z $path);
	}
}
############################## checkTimestamp ##############################
sub checkTimestamp {
	my $path=shift();
	if($path=~/^(.+\@.+)\:(.+)$/){
		my $stat=`ssh $1 'perl -e \"my \@array=stat(\\\$ARGV[0]);print \\\$array[9]\" $2'`;
		if($stat eq ""){return;}
		return $stat;
	}else{
		my @stats=stat($path);
		return $stats[9];
	}
}
############################## checkQuery ##############################
sub checkQuery{
	my @queries=@_;
	my $hit=0;
	foreach my $query(@queries){
		my $i=0;
		foreach my $node(split(/->/,$query)){
			if($node=~/^\$[\w_]+$/){}
			elsif($node=~/^\$(\w+)/){
				my $label=($i==0)?"subject":($i==1)?"predicate":"object";
				print STDERR "ERROR : '$node' can't be used as $label in query '$query'.\n";
				print STDERR "      : Please specify '\$$1' variable in argument with '\$$1=???????'.\n";
				$hit++;
			}
			$i++;
		}
	}
	return $hit;
}
############################## commandProcess ##############################
sub commandProcess{
	my @arguments=@_;
	my $url=shift(@arguments);
	my $commands=shift(@arguments);
	my $queryResults=shift(@arguments);
	my $userdefined=shift(@arguments);
	my $queryKeys=shift(@arguments);
	my $insertKeys=shift(@arguments);
	my $cmdLine=shift(@arguments);
	my $command=loadCommandFromURL($url,$commands);
	$commands->{$url}=$command;
	my @inputs=@{$command->{$urls->{"daemon/input"}}};
	my @outputs=@{$command->{$urls->{"daemon/output"}}};
	if(defined($insertKeys)){push(@{$command->{"insertKeys"}},@{$insertKeys});}
	if(defined($queryKeys)){push(@{$command->{"queryKeys"}},@{$queryKeys});}
	if(defined($opt_a)){
		if($opt_a=~/^(.+)\@(.+)$/){
			$commands->{$cmdurl}->{$urls->{"daemon/username"}}=$1;
			$commands->{$cmdurl}->{$urls->{"daemon/server"}}=$2;
		}else{
			my $username=`whoami`;chomp($username);
			$commands->{$cmdurl}->{$urls->{"daemon/username"}}=$username;
			$commands->{$cmdurl}->{$urls->{"daemon/server"}}=$opt_a;
		}
	}
	if(defined($opt_c)){$commands->{$cmdurl}->{$urls->{"daemon/container"}}=$opt_c;}
	if(defined($opt_q)){$commands->{$cmdurl}->{$urls->{"daemon/qjob"}}=$opt_q;}
	if(defined($opt_Q)){$commands->{$cmdurl}->{$urls->{"daemon/qjob/opt"}}=$opt_Q;}
	if(defined($opt_r)){$commands->{$cmdurl}->{$urls->{"daemon/return"}}=removeDollar($opt_r);}
	if(defined($opt_f)){$commands->{$cmdurl}->{$urls->{"daemon/filestats"}}=handleValues($opt_f);}
	if(defined($opt_l)){
		my $line="#Command: ".basename($command->{$urls->{"daemon/command"}});
		if(scalar(@inputs)>0){$line.=" \$".join(" \$",@inputs);}
		if(scalar(@outputs)>0){$line.=" \$".join(" \$",@outputs);}
		print STDERR "$line\n";
	}
	foreach my $input(@inputs){
		if(scalar(@arguments)==0){last;}
		if(exists($userdefined->{$input})){next;}
		$userdefined->{$input}=shift(@arguments);
	}
	foreach my $output(@outputs){
		if(scalar(@arguments)==0){last;}
		if(exists($userdefined->{$output})){next;}
		$userdefined->{$output}=shift(@arguments);
	}
	assignCommand($command,$userdefined,$queryResults);
	my @execids=();
	my $keys;
	foreach my $hash(@{$queryResults->[1]}){
		my $vars=commandProcessVars($hash,$userdefined,$insertKeys,\@inputs,\@outputs);
		if(!defined($keys)){my @temp=sort{$a cmp $b}keys(%{$vars});$keys=\@temp;}
		my $execid=commandProcessSub($url,$vars,$cmdLine,\@inputs,\@outputs);
		push(@execids,$execid);
	}
	if(defined($opt_u)){
		print STDERR "Proceed running ".scalar(@execids)." jobs [y/n]? ";
		my $prompt=<STDIN>;
		chomp($prompt);
		if($prompt ne "y"&&$prompt ne "yes"&&$prompt ne "Y"&&$prompt ne "YES"){exit(1);}
	}
	return @execids;
}
############################## commandProcessSub ##############################
sub commandProcessSub{
	my $url=shift();
	my $vars=shift();
	my $cmdLine=shift();
	my $inputs=shift();
	my $outputs=shift();
	my @inserts=();
	my $id="e".getDatetime();
	my $dirname=substr($id,1,8);
	my $logfile="$jobdir/$dirname/$id.txt";
	while(existsLogFile($logfile)){
		sleep(1);
		$id="e".getDatetime();
		$logfile="$jobdir/$dirname/$id.txt";
	}
	my @lines=();
	push(@lines,$urls->{"daemon/command"}."\t$url");
	foreach my $key(keys(%{$vars})){push(@lines,"$url#$key\t".$vars->{$key});}
	writeLog($id,@lines);
	return $id;
}
############################## commandProcessVars ##############################
sub commandProcessVars{
	my $hash=shift();
	my $userdefined=shift();
	my $insertKeys=shift();
	my @inputs=@{shift()};
	my @outputs=@{shift()};
	my $vars={};
	for(my $i=0;$i<scalar(@inputs);$i++){
		my $input=$inputs[$i];
		my $value=$input;
		my $found=0;
		if(exists($hash->{$value})){$value=$hash->{$value};$found=1;}
		if(exists($userdefined->{$value})){$value=$userdefined->{$value};$found=1;}
		if($found==1){$vars->{$input}=$value;}
	}
	for(my $i=0;$i<scalar(@outputs);$i++){
		my $output=$outputs[$i];
		my $value=$output;
		my $found=0;
		if(exists($hash->{$value})){$value=$hash->{$value};$found=1;}
		if(exists($userdefined->{$value})){
			$value=$userdefined->{$value};
			if($value=~/\$(\w+)\.(\w+)/){
				if(exists($vars->{$1})){
					my $h=basenames($vars->{$1});
					if(exists($h->{$2})){my $k="\\\$$1\\.$2";my $v=$h->{$2};$value=~s/$k/$v/g;}
				}
			}elsif($value=~/\$\{(\w+)\.(\w+)\}/){
				if(exists($vars->{$1})){
					my $h=basenames($vars->{$1});
					if(exists($h->{$2})){my $k="\\\$\\{$1\\.$2\\}";my $v=$h->{$2};$value=~s/$k/$v/g;}
				}
			}
			$found=1;
		}
		if($found==1){$vars->{$output}=$value;}
	}
	while(my($key,$val)=each(%{$hash})){if(!exists($vars->{$key})){$vars->{$key}=$val;}}
	return $vars;
}
############################## compareFiles ##############################
sub compareFiles{
	my $fileA=shift();
	my $fileB=shift();
	open(INA,$fileA);
	open(INB,$fileB);
	while(!eof(INA)){
		my $lineA=<INA>;
		my $lineB=<INB>;
		if($fileA ne $fileB){return;}
	}
	close(INB);
	close(INA);
	return 1;
}
############################## controlInsert ##############################
sub controlInsert{
	my @files=getFiles("$ctrldir/insert");
	if(scalar(@files)==0){return 0;}
	my $command="cat ".join(" ",@files)."|perl $prgdir/rdf.pl -q -d $moiraidir -f tsv insert";
	my $count=`$command`;
	foreach my $file(@files){unlink($file);}
	$count=~/(\d+)/;
	$count=$1;
	return $count;
}
############################## completeProcess ##############################
sub completeProcess{
	my $process=shift();
	my $status=shift();
	my $execid=$process->{$urls->{"daemon/execid"}};
	my $srcdir="$rootdir/$moiraidir/$execid";
	my $workdir=$process->{$urls->{"daemon/workdir"}};
	my $stderrfile="$workdir/stderr.txt";
	my $stdoutfile="$workdir/stdout.txt";
	my $statusfile="$workdir/status.txt";
	my $logfile="$workdir/log.txt";
	my $bashfile="$workdir/run.sh";
	my $processfile="$processdir/$execid.txt";
	my $dirname=substr($execid,1,8);
	my $jobfile="$jobdir/$execid.txt";
	my $outputfile="$logdir/$dirname/$execid.txt";
	mkdir(dirname($outputfile));
	my $insertdir="$ctrldir/insert";
	my $triples={};
	#processfile
	my $timeregistered;
	my $execid;
	my $reader=openFile($processfile);
	while(<$reader>){
		chomp;my ($key,$val)=split(/\t/);$triples->{$key}=$val;
		if($key eq $urls->{"daemon/timeregistered"}){$timeregistered=$val;}
		if($key eq $urls->{"daemon/execid"}){$execid=$val;}
	}
	close($reader);
	#logfile
	my $logs={};
	if(checkTimestamp($logfile)){
		$reader=openFile($logfile);
		while(<$reader>){
			chomp;my ($key,$val)=split(/\t/);
			if(!exists($logs->{$key})){$logs->{$key}=$val;}
			elsif(ref($logs->{$key})eq"ARRAY"){push(@{$logs->{$key}},$val);}
			elsif($key eq $urls->{"daemon/execute"}){$logs->{$key}=$val;}
			elsif($key eq $urls->{"daemon/execid"} && $val ne $execid){print STDERR "SYSTEM ERROR: Execid of '$execid' doesn't match...\n";}
			else{$logs->{$key}=[$logs->{$key},$val];}
		}
		close($reader);
	}
	while(my ($key,$val)=each(%{$logs})){$triples->{$key}=$val;}
	#statusfile
	my $timestarted;
	my $timeended;
	$reader=openFile($statusfile);
	while(<$reader>){
		chomp;my ($key,$time)=split(/\t/);
		if($key eq "start"){$triples->{$urls->{"daemon/timestarted"}}=$time;$timestarted=$time;}
		elsif($key eq "end"){$triples->{$urls->{"daemon/timeended"}}=$time;$timeended=$time;}
		elsif($key eq "completed"){$triples->{$urls->{"daemon/timecompleted"}}=$time;$triples->{$urls->{"daemon/execute"}}="completed";}
		elsif($key eq "error"){$triples->{$urls->{"daemon/timecompleted"}}=$time;$triples->{$urls->{"daemon/execute"}}="error";}
	}
	close($reader);
	$triples->{$urls->{"daemon/processtime"}}=$timeended-$timestarted;
	#write logfile
	my ($logwriter,$logoutput)=tempfile(SUFFIX=>".txt");
	print $logwriter "######################################## $execid ########################################\n";
	foreach my $key(sort{$a cmp $b}keys(%{$triples})){
		if(ref($triples->{$key})eq"ARRAY"){foreach my $val(@{$triples->{$key}}){print $logwriter "$key\t$val\n";}}
		else{print $logwriter "$key\t".$triples->{$key}."\n";}
	}
	print $logwriter "######################################## log ########################################\n";
	#statusfile
	my $reader=openFile($statusfile);
	print $logwriter "registered\t$timeregistered\n";
	while(<$reader>){chomp;print $logwriter "$_\n";}
	close($reader);
	#stdoutfile
	my ($insertwriter,$insertfile)=tempfile(SUFFIX=>".txt");
	$reader=openFile($stdoutfile);
	my $stdoutcount=0;
	my $insertcount=0;
	while(<$reader>){
		chomp;
		if(/(.+)\-\>(.+)\-\>(.+)/){print $insertwriter "$1\t$2\t$3\n";$insertcount++;next;}
		if($stdoutcount==0){print $logwriter "######################################## stdout ########################################\n";}
		print $logwriter "$_\n";$stdoutcount++;
	}
	close($reader);
	close($insertwriter);
	#stderrfile
	$reader=openFile($stderrfile);
	my $stderrcount=0;
	while(<$reader>){
		chomp;
		if($stderrcount==0){print $logwriter "######################################## stderr ########################################\n";}
		print $logwriter "$_\n";$stderrcount++;
	}
	close($reader);
	#insertfile
	if($insertcount>0){
		print $logwriter "######################################## insert ########################################\n";
		my $reader=openFile($insertfile);
		while(<$reader>){chomp;print $logwriter "$_\n";}
		close($reader);
		system("mv $insertfile $insertdir/".basename($insertfile));
	}else{unlink($insertfile);}
	#bashfile
	print $logwriter "######################################## bash ########################################\n";
	my $reader=openFile($bashfile);
	while(<$reader>){chomp;print $logwriter "$_\n";}
	close($reader);
	close($logwriter);
	#complete
	system("mv $logoutput $outputfile");
	removeFiles($bashfile,$logfile,$statusfile,$stdoutfile,$stderrfile,$jobfile,$processfile);
	removeDirs($srcdir,$workdir);
	#if($status eq "completed"){system("gzip $outputfile");}
	if($status eq "completed"){}
	elsif($status eq "error"){system("mv $outputfile $errordir/".basename($outputfile));}
}
############################## controlProcess ##############################
sub controlProcess{
	my $processes=shift();
	my $completed=0;
	foreach my $execid(keys(%{$processes})){
		my $process=$processes->{$execid};
		my $status=checkProcessStatus($process);
		if(!defined($status)){next;}
		if($status eq "completed"||$status eq "error"){
			completeProcess($process,$status);
		}else{
			writeLog($execid,$urls->{"daemon/execute"}."\t$status");
		}
	}
	return $completed;
}
############################## controlWorkflow ##############################
sub controlWorkflow{
	my $executes=shift();
	my $processes=shift();
	my $inserted=controlInsert();
	my $completed=controlProcess($processes);
	$inserted+=controlSubmit();
	if(!defined($opt_l)){return;}
	my $date=getDate("/");
	my $time=getTime(":");
	if($completed>0){
		my $remain=getNumberOfJobsRemaining($executes);
		if($completed>1){print "$date $time Completed $completed jobs (Remaining $remain).\n";}
		else{print "$date $time Completed $completed job ($remain remain).\n";}
	}
	if($inserted>1){print "$date $time Inserted $inserted triples.\n";}
	elsif($inserted>0){print "$date $time Inserted $inserted triple.\n";}
}
############################## controlSubmit ##############################
sub controlSubmit{
	my @files=getFiles("$ctrldir/submit");
	if(scalar(@files)==0){return 0;}
	my $total=0;
	foreach my $file(@files){
		my $command="perl $prgdir/rdf.pl";
		if(!defined($opt_l)){$command.=" -q";}
		$command.=" -d $moiraidir -f tsv submit<$file";
		$total+=`$command`;
		sleep(1);
		unlink($file);
	}
	return $total;
}
############################## createJson ##############################
sub createJson{
	my @commands=@_;
	my $dir=shift(@commands);
	my $inputs=shift(@commands);
	my $outputs=shift(@commands);
	my $scripts=shift(@commands);
	my ($writer,$file)=tempfile(DIR=>$dir,SUFFIX=>".json");
	print $writer "{";
	print $writer "\"".$urls->{"daemon/bash"}."\":".jsonEncode(\@commands);
	if(scalar(@{$inputs})>0){print $writer ",\"".$urls->{"daemon/input"}."\":[\"".join("\",\"",@{$inputs})."\"]";}
	if(scalar(@{$outputs})>0){print $writer ",\"".$urls->{"daemon/output"}."\":[\"".join("\",\"",@{$outputs})."\"]";}
	if(defined($opt_b)){
		my @temp=();
		foreach my $token(split(/\,/,$opt_b)){my ($key,$val)=split(/\:/,$token);push(@temp,"\"$key\":\"$val\"");}
		print $writer ",\"".$urls->{"daemon/command/option"}."\":{".join(",",@temp)."}";
	}
	if(defined($opt_F)){
		my @temp=();
		foreach my $token(split(/\,/,$opt_F)){if($token!~/^\$/){$token="\$token";}push(@temp,$token);}
		print $writer ",\"".$urls->{"daemon/error/file/empty"}."\":[".join(",",@temp)."]";
	}
	if(defined($opt_c)){print $writer ",\"".$urls->{"daemon/container"}."\":\"$opt_c\"";}
	if(defined($opt_q)){print $writer ",\"".$urls->{"daemon/qjob"}."\":\"$opt_q\"";}
	if(defined($opt_Q)){print $writer ",\"".$urls->{"daemon/qjob/opt"}."\":\"$opt_Q\"";}
	if(defined($opt_O)){print $writer ",\"".$urls->{"daemon/error/stdout/ignore"}."\":[\"$opt_O\"]";}
	if(defined($opt_E)){print $writer ",\"".$urls->{"daemon/error/stderr/ignore"}."\":[\"$opt_E\"]";}
	if(scalar(@{$scripts}>0)){print $writer ",".encodeScripts(@{$scripts});}
	print $writer "}";
	close($writer);
	if($file=~/^\.\/(.+)$/){$file=$1;}
	my $json;
	if(defined($md5cmd)){
		my $md5=`$md5cmd<$file`;chomp($md5);
		foreach my $tmp(listFiles("json",$jsondir)){
			my $md=`$md5cmd<$tmp`;chomp($md);
			if($md eq $md5){$json=$tmp;}
		}
	}else{
		my $sizeA=-s $file;
		foreach my $tmp(listFiles("json",$jsondir)){
			my $sizeB=-s $tmp;
			if($sizeA!=$sizeB){next;}
			if(compareFiles($sizeA,$sizeB)){$json=$sizeB;last;}
		}
	}
	if(defined($json)){
		unlink($file);
	}else{
		$json="$jsondir/j".getDatetime().".json";
		while(-e $json){sleep(1);$json="$jsondir/j".getDatetime().".json";}
		system("mv $file $json");
	}
	return $json;
}
############################## daemon ##############################
sub daemon{
	my @directories=@_;
	if(scalar(@directories)==0){push(@directories,".");}
	my $sleeptime=defined($opt_s)?$opt_s:10;
	my $logdir=defined($opt_o)?$opt_o:"daemon";
	my $databases={};
	my $stderrs={};
	my $stdouts={};
	my $logs={};
	my $directory=defined($opt_d)?$opt_d:".";
	while(1){
		foreach my $dirname(listMoirais(@directories)){
			if(!exists($databases->{$dirname})){
				if(-e "$logdir/$dirname"){
					my @stats=stat("$logdir/$dirname");
					$databases->{$dirname}=$stats[9];
				}else{$databases->{$dirname}=0;}
			}
		}
		while(my($database,$timestamp)=each(%{$databases})){
			my $dirname=dirname($database);
			my $basename=basename($database);
			my @stats=stat($database);
			my $modtime=$stats[9];
			if($timestamp==0){$databases->{$database}=$modtime;$timestamp=$modtime;}
			if(-e "$logdir/$basename.lock" && -e "$logdir/$basename.unlock"){
				unlink("$logdir/$basename.lock");
				unlink("$logdir/$basename.unlock");
				$databases->{$database}=$modtime;
				next;
			}
			if(-e "$logdir/$basename.lock"){next;}
			if(checkCtrlDirectory("$dirname/$basename")){}
			elsif($modtime>$timestamp){}
			else{next;}
			if(!(-e "$logdir/$basename")){mkdirs("$logdir/$basename");}
			my $aCommand="perl moirai2.pl -d $database";
			if(defined($opt_q)){$aCommand.=" -q $opt_q"}
			if(defined($opt_Q)){$aCommand.=" -Q $opt_Q"}
			if(defined($opt_m)){$aCommand.=" -m $opt_m"}
			my $time=time();
			my $datetime=getDate("",$time).getTime("",$time);
			if(!exists($stdouts->{$database})){$stdouts->{$database}="$logdir/$basename/$datetime.stdout";}
			$aCommand.=" -O ".$stdouts->{$database};
			if(!exists($stderrs->{$database})){$stderrs->{$database}="$logdir/$basename/$datetime.stderr";}
			$aCommand.=" -E ".$stderrs->{$database};
			$aCommand.=" automate";
			my $shell="$logdir/$basename/daemon.sh";
			open(OUT,">$shell");
			print OUT "touch $logdir/$basename.lock\n";
			print OUT "$aCommand\n";
			print OUT "touch $logdir/$basename.unlock\n";
			print OUT "rm $shell\n";
			close(OUT);
			my $bCommand="bash $shell &";
			if(defined($opt_l)){print STDERR "$bCommand\n";}
			system($bCommand);
			$databases->{$database}=$modtime;
		}
		sleep($sleeptime);
	}
}
############################## encodeScripts ##############################
sub encodeScripts{
	my @scripts=@_;
	my @codes=();
	foreach my $script(@scripts){
		my $filename=basename($script);
		my @lines=();
		open(IN,$script);
		while(<IN>){
			chomp;
			push(@lines,$_);
		}
		close(IN);
		my $code="{\"".$urls->{"daemon/script/name"}."\":\"$filename\",";
		$code.="\"".$urls->{"daemon/script/code"}."\":".jsonEncode(\@lines)."}";
		push(@codes,$code);
	}
	my $line="\"".$urls->{"daemon/script"}."\":";
	if(scalar(@codes)>1){$line.="[".join(",",@codes)."]";}
	else{$line.=join(",",@codes);}
	return $line;
}
############################## existsArray ##############################
sub existsArray{
	my $array=shift();
	my $needle=shift();
	foreach my $value(@{$array}){if($needle eq $value){return 1;}}
	return 0;
}
############################## existsLogFile ##############################
sub existsLogFile{
	my $file=shift();
	if(-e $file){return 1;}
	if(-e "$file.gz"){return 1;}
	if(-e "$file.bz2"){return 1;}
	return 0;
}
############################## existsString ##############################
sub existsString{
	my $string=shift();
	my $lines=shift();
	foreach my $line(@{$lines}){if($line=~/$string/){return 1;}}
}
############################## extract ##############################
sub extract{
	my @urls=@_;
	my $outdir=$opt_o;
	if(!defined($outdir)){$outdir="out";}
	mkdir($outdir);
	foreach my $url(@urls){
		foreach my $out(writeScript($url,$outdir,$commands)){print "$out\n";}
	}
}
############################## fileStats ##############################
sub fileStats{
	my $path=shift();
	my $line=shift();
	my $hash=shift();
	if(!defined($hash)){$hash={};}
	my @variables=("linecount","seqcount","filesize","filecount","md5","timestamp","owner","group","permission","check");
	my $matches={};
	foreach my $v(@variables){if($line=~/\$\{$v\}/||$line=~/\$$v/){$matches->{$v}=1;}}
	foreach my $key(keys(%{$matches})){
		my @stats=stat($path);
		if($key eq "filesize"){$hash->{$key}=$stats[7];}
		elsif($key eq "md5"&&defined($md5cmd)){my $md5=`$md5cmd<$path`;chomp($md5);$hash->{$key}=$md5;}
		elsif($key eq "timestamp"){$hash->{$key}=$stats[9];}
		elsif($key eq "owner"){$hash->{$key}=getpwuid($stats[4]);}
		elsif($key eq "group"){$hash->{$key}=getgrgid($stats[5]);}
		elsif($key eq "permission"){$hash->{$key}=$stats[2]&07777;}
		elsif($key eq "filecount"){if(!(-f $path)){$hash->{$key}=0;}else{my $count=`ls $path|wc -l`;chomp($count);$hash->{$key}=$count;}}
		elsif($key eq "linecount"){$hash->{$key}=linecount($path);}
		elsif($key eq "seqcount"){$hash->{$key}=seqcount($path);}
		elsif($key eq "check"){$hash->{$key}=check($path);}
	}
	return $hash;
}
############################## getBash ##############################
sub getBash{
	my $url=shift();
	my $username=shift();
	my $password=shift();
	my $content=($url=~/https?:\/\//)?getHttpContent($url,$username,$password):getFileContent($url);
	my $hash={};
	my $line;
	my @lines=();
	foreach my $c(split(/\n/,$content)){
		if($c=~/^#\$\s?-q\s+?(.+)$/){$hash->{$urls->{"daemon/qjob"}}=$1;}
		elsif($c=~/^#\$\s?-Q\s+?(.+)$/){$hash->{$urls->{"daemon/qjob/opt"}}=$1;}
		elsif($c=~/^\s*(.+)\s+\\$/){
			if(defined($line)){$line.=" $1";}
			else{$line=$1;}
		}elsif(defined($line)){
			$line.=" $c";
			push(@lines,$line);
			$line=undef;
		}else{push(@lines,$c);}
	}
	if(defined($line)){push(@lines,$line);}
	foreach my $line(@lines){
		if($line=~/(perl )?moirai2\.pl/){
			if(defined($opt_d)){$line=~s/\s+\-d\s+(\S+)//;}
			$line=~s/moirai2\.pl/moirai2.pl -d $moiraidir/;
		}
	}
	$hash->{$urls->{"daemon/bash"}}=\@lines;
	return $hash;
}
############################## getDate ##############################
sub getDate{
	my $delim=shift;
	my $time=shift;
	if(!defined($delim)){$delim="";}
	if(!defined($time)||$time eq ""){$time=localtime();}
	else{$time=localtime($time);}
	my $year=$time->year+1900;
	my $month=$time->mon+1;
	if($month<10){$month="0".$month;}
	my $day=$time->mday;
	if($day<10){$day="0".$day;}
	return $year.$delim.$month.$delim.$day;
}
############################## getDatetime ##############################
sub getDatetime{my $time=shift;return getDate("",$time).getTime("",$time);}
############################## getExecuteJobs ##############################
sub getExecutes{
	my @ids=@ARGV;
	my $url=shift(@ids);
	my $logs=loadLogs();
	my $hash={};
	foreach my $id(@ids){$hash->{$id}=1;}
	my $executes={};
	foreach my $id(keys(%{$logs})){
		if(exists($hash->{$id})){next;}
		if(exists($logs->{$id}->{$urls->{"daemon/execute"}})){next;}
		if($logs->{$id}->{$urls->{"daemon/command"}}ne $url){next;}
		if(!exists($executes->{$id})){$executes->{$id}={};}
		while(my ($key,$val)=each(%{$logs->{$id}})){
			if($key eq $urls->{"daemon/execute"}){next;}
			if($key eq $urls->{"daemon/command"}){next;}
			if($key=~/^$url#(.+)$/){
				$key=$1;
				if(!exists($executes->{$id}->{$key})){$executes->{$id}->{$key}=$val;}
				elsif(ref($executes->{$id}->{$key})eq"ARRAY"){push(@{$executes->{$id}->{$key}},$val);}
				else{$executes->{$id}->{$key}=[$executes->{$id}->{$key},$val]}
			}
		}
	}
	print jsonEncode($executes)."\n";
}
sub getExecuteJobs{
	my $dbdir=shift();
	my $command=shift();
	my $executes=shift();
	my $url=$command->{$urls->{"daemon/command"}};
	my $execids={};
	foreach my $execute(@{$executes->{$url}}){$execids->{$execute->{"execid"}}=1;}
	my $command="perl $prgdir/rdf.pl -d $moiraidir -f json executes $url ".join(" ",keys(%{$execids}));
	my $vars=jsonDecode(`$command`);
	foreach my $key(keys(%{$vars})){$vars->{$key}->{"execid"}=$key;}
	my $count=0;
	foreach my $key(sort{$a cmp $b}keys(%{$vars})){push(@{$executes->{$url}},$vars->{$key});$count++;}
	return $count;
}
############################## getFileContent ##############################
sub getFileContent{
	my $path=shift();
	open(IN,$path);
	my $content;
	while(<IN>){s/\r//g;$content.=$_;}
	close(IN);
	return $content;
}
############################## getFileFromExecid ##############################
sub getFileFromExecid{
	my $execid=shift();
	my $dirname=substr($execid,1,8);
	if(-e "$errordir/$execid.txt"){return "$errordir/$execid.txt";}
	elsif(-e "$logdir/$dirname/$execid.txt"){return "$logdir/$dirname/$execid.txt";}
	elsif(-e "$logdir/$dirname.tgz"){return "$logdir/$dirname.tgz";}
}
############################## getFiles ##############################
sub getFiles{
	my $directory=shift();
	my @files=();
	opendir(DIR,$directory);
	foreach my $file(readdir(DIR)){
		if($file=~/^\./){next;}
		if($file eq ""){next;}
		push(@files,"$directory/$file");
	}
	closedir(DIR);
	return @files;
}
############################## getHttpContent ##############################
sub getHttpContent{
	my $url=shift();
	my $username=shift();
	my $password=shift();
	my $agent=new LWP::UserAgent();
	my $request=HTTP::Request->new(GET=>$url);
	if($username ne ""||$password ne ""){$request->authorization_basic($username,$password);}
	my $res=$agent->request($request);
	if($res->is_success){return $res->content;}
	elsif($res->is_error){print $res;}
}
############################## getInputsOutputsFromCommand ##############################
sub getInputsOutputsFromCommand{
	my $command=shift();
	my $userdefined=shift();
	my $files={};
	while($command=~/([\w\_\/\.]+\.\w{3,4})/g){$files->{$1}=1;}
	my @temps=sort{$a cmp $b}keys(%{$files});
	foreach my $file(@temps){
		print STDERR "$file is [I]nput/[O]utput? ";
		while(<STDIN>){
			chomp();
			if(/^i/i){$files->{$file}="input";last;}
			elsif(/^o/i){$files->{$file}="output";last;}
			print STDERR "Please type 'i' or 'o' only\n";
			print STDERR "$file is [I]nput/[O]utput? ";
		}
	}
	my @inputs=();
	my @outputs=();
	my $variables={};
	while(my ($file,$type)=each(%{$files})){
		my $name;
		if($type eq "input"){
			$name="input".(scalar(@inputs)+1);
			push(@inputs,$name);
		}elsif($type eq "output"){
			$name="output".(scalar(@outputs)+1);
			push(@outputs,$name);
		}else{next;}
		$command=~s/$file/\$$name/g;
		$userdefined->{$name}=$file;
	}
	return ($command,\@inputs,\@outputs);
}
############################## getJson ##############################
sub getJson{
	my $url=shift();
	my $username=shift();
	my $password=shift();
	my $content=($url=~/https?:\/\//)?getHttpContent($url,$username,$password):getFileContent($url);
	my $directory=dirname($url);
	$content=~s/\$this/$url/g;
	$content=~s/\$\{this:directory\}/$directory/g;
	return jsonDecode($content);
}
############################## getNumberOfJobsRemaining ##############################
sub getNumberOfJobsRemaining{
	my $executes=shift();
	my $count=0;
	foreach my $url(keys(%{$executes})){$count+=scalar(keys(%{$executes->{$url}}));}
	return $count;
}
############################## getNumberOfJobsRunning ##############################
sub getNumberOfJobsRunning{my @files=getFiles("$ctrldir/process");return scalar(@files);}
############################## getQueryResults ##############################
sub getQueryResults{
	my $dbdir=shift();
	my $input=shift();
	my @queries=split(/,/,$input);
	my $command="perl $prgdir/rdf.pl -d $moiraidir -f json query '".join("' '",@queries)."'";
	my $result=`$command`;chomp($result);
	my $hashs=jsonDecode($result);
	my $temp={};
	foreach my $hash(@{$hashs}){foreach my $key(keys(%{$hash})){$temp->{$key}=1;}}
	my @keys=keys(%{$temp});
	return [\@keys,$hashs];
}
############################## getTime ##############################
sub getTime{
	my $delim=shift;
	my $time=shift;
	if(!defined($delim)){$delim="";}
	if(!defined($time)||$time eq ""){$time=localtime();}
	else{$time=localtime($time);}
	my $hour=$time->hour;
	if($hour<10){$hour="0".$hour;}
	my $minute=$time->min;
	if($minute<10){$minute="0".$minute;}
	my $second=$time->sec;
	if($second<10){$second="0".$second;}
	return $hour.$delim.$minute.$delim.$second;
}
############################## handleArguments ##############################
sub handleArguments{
	my @arguments=@_;
	my $variables={};
	my @array=();
	my $index;
	for($index=scalar(@arguments)-1;$index>=0;$index--){
		my $argument=$arguments[$index];
		if($argument=~/\;$/){last;}
		elsif($argument=~/^(\$?\w+)\=(.+)$/){
			my $key=$1;
			my $val=$2;
			if($key=~/^\$(.+)$/){$key=$1;}
			$variables->{$key}=$val;
		}else{last;}
	}
	for(my $i=0;$i<=$index;$i++){push(@array,$arguments[$i]);}
	return (\@array,$variables);
}
############################## handleArray ##############################
sub handleArray{
	my $array=shift();
	my $defaults=shift();
	if(!defined($defaults)){$defaults={};}
	if(!defined($array)){return [];}
	if(ref($array)ne"ARRAY"){
		if($array=~/,/){my @temp=split(/,/,$array);$array=\@temp;}
		else{$array=[$array];}
	}
	my @temps=();
	foreach my $variable(@{$array}){
		if(ref($variable)eq"HASH"){
			foreach my $key(keys(%{$variable})){
				my $value=$variable->{$key};
				if($key=~/^\$(.+)$/){$key=$1;}
				push(@temps,$key);
				$defaults->{$key}=$value;
			}
			next;
		}elsif($variable=~/^\$(.+)$/){$variable=$1;}
		push(@temps,$variable)
	}
	return \@temps;
}
############################## handleCode ##############################
sub handleCode{
	my $code=shift();
	if(ref($code) eq "ARRAY"){return $code;}
	my @lines=split(/\n/,$code);
	return \@lines;
}
############################## handleHash ##############################
sub handleHash{
	my @array=@_;
	my $hash={};
	foreach my $input(@array){$hash->{$input}=1;}
	return $hash;
}
############################## handleInputOutput ##############################
sub handleInputOutput{
	my $statement=shift();
	my @array=();
	my @statements;
	if(ref($statement) eq "ARRAY"){@statements=@{$statement};}
	else{@statements=split(",",$statement);}
	foreach my $line(@statements){my @tokens=split(/\-\>/,$line);push(@array,\@tokens);}
	return \@array;
}
############################## handleScript ##############################
sub handleScript{
	my $command=shift();
	my $scripts=$command->{$urls->{"daemon/script"}};
	if(ref($scripts)ne"ARRAY"){$scripts=[$scripts];}
	foreach my $script(@{$scripts}){
		my $name=$script->{$urls->{"daemon/script/name"}};
		my $code=$script->{$urls->{"daemon/script/code"}};
		if(ref($code)ne"ARRAY"){$code=[$code];}
		$command->{$name}=$code;
		push(@{$command->{"script"}},$name);
	}
	$command->{$urls->{"daemon/script"}}=$scripts;
}
############################## handleValues ##############################
sub handleValues{
	my $line=shift();
	my @keys=split(/,/,$line);
	foreach my $key(@keys){if($key=~/^\$(.+)$/){$key=$1;}}
	return \@keys;
}
############################## html ##############################
sub html{
	print "<html>\n";
	print "<head>\n";
	print "<title>$basename</title>\n";
	print "<script type=\"text/javascript\" src=\"js/vis/vis-network.min.js\"></script>\n";
	print "<script type=\"text/javascript\" src=\"js/jquery/jquery-3.4.1.min.js\"></script>\n";
	print "<script type=\"text/javascript\" src=\"js/jquery/jquery.columns.min.js\"></script>\n";
	print "<script type=\"text/javascript\">\n";
	my $network=`perl $prgdir/rdf.pl -d $moiraidir export network`;
	chomp($network);
	my $db=`perl $prgdir/rdf.pl -d $moiraidir export db`;
	chomp($db);
	my $log=`perl $prgdir/rdf.pl -d $moiraidir export log`;
	chomp($log);
	print "var network=$network;\n";
	print "var db=$db;\n";
	print "var log=$log;\n";
    print "var nodes = new vis.DataSet(network[0]);\n";
    print "var edges = new vis.DataSet(network[1]);\n";
	print "\$(document).ready(function() {\n";
	print "	var container=\$(\"#network\")[0];\n";
    print "	var data={nodes:nodes,edges:edges,};\n";
    print "	var options={edges:{arrows:'to'}};\n";
    print "	var network=new vis.Network(container,data,options);\n";
	print "	network.on(\"click\",function(params){\n";
    print "		if (params.nodes.length==1) {\n";
    print "			var nodeId=params.nodes[0];\n";
    print "			var node=nodes.get(nodeId);\n";
    print "			console.log(params.event.srcEvent.shiftKey);\n";
    print "			console.log(node.label+' clicked!');\n";
    print "		}\n";
    print "		if (params.edges.length==1) {\n";
	print "			var edgeId=params.edges[0];\n";
	print "			var edge=edges.get(edgeId);\n";
	print "			console.log(edge.label+' clicked!');\n";
	print "		}\n";
  	print "	});\n";
	print "\$('#dbs').columns({\n";
    print "data:db,\n";
	print "});\n";
	print "\$('#logs').columns({\n";
    print "data:log,\n";
    print "schema: [\n";
    print "{'header': 'execid', 'key': 'daemon/execid'},\n";
    print "{'header': 'execute', 'key': 'daemon/execute'},\n";
    print "{'header': 'timeregistered', 'key': 'daemon/timeregistered'},\n";
    print "{'header': 'timestarted', 'key': 'daemon/timestarted'},\n";
    print "{'header': 'timeended', 'key': 'daemon/timeended'},\n";
    print "{'header': 'command', 'key': 'daemon/command','template':'<a href=\"{{daemon/command}}\">{{daemon/command}}</a>'}\n";
  	print "]\n";
	print "});\n";
	print "});\n";
	print "</script>\n";
	print "<link rel=\"stylesheet\" href=\"css/classic.css\">\n";
	print "<style type=\"text/css\">\n";
    print "#network {\n";
    print "width: 600px;\n";
    print "height: 400px;\n";
    print "border: 1px solid lightgray;\n";
    print "}\n";
	print "</style>\n";
	print "</head>\n";
	print "<body>\n";
	print "<h1>$basename</h1>\n";
	print "updated: ".getDate("/")." ".getTime(":")."\n";
	print "<hr>\n";
    print "<div id=\"network\"></div>\n";
    print "<div id=\"dbs\"></div>\n";
    print "<div id=\"logs\"></div>\n";
	print "</body>\n";
	print "</html>\n";
}
############################## initExecute ##############################
sub initExecute{
	my $dbdir=shift();
	my $command=shift();
	my $vars=shift();
	if(!defined($vars)){$vars={};}
	my $url=$command->{$urls->{"daemon/command"}};
	my $execid=$vars->{"execid"};
	my $workdir="$moiraidir/$execid";
	mkdir($workdir);
	chmod(0777,$workdir);
	$vars->{"cmdurl"}=$url;
	$vars->{"rootdir"}=$rootdir;
	$vars->{"binddir"}=$rootdir;
	$vars->{"workdir"}=$workdir;
	$vars->{"tmpdir"}="$workdir/tmp";
	$vars->{"bashsrc"}="$rootdir/$workdir/run.sh";
	$vars->{"bashfile"}="$rootdir/$workdir/run.sh";
	$vars->{"stderrfile"}="$rootdir/$workdir/stderr.txt";
	$vars->{"stdoutfile"}="$rootdir/$workdir/stdout.txt";
	if(exists($command->{$urls->{"daemon/server"}})){
		my $server=$command->{$urls->{"daemon/server"}};
		my $username=$command->{$urls->{"daemon/username"}};
		my $homedir="/home/$username/moirai2";
		$workdir="$homedir/$moiraidir/$execid";
		$vars->{"rootdir"}=$homedir;
		$vars->{"binddir"}=$homedir;
		$vars->{"bashfile"}="$workdir/run.sh";
		$vars->{"bashscp"}="$workdir/run.sh";
		$vars->{"workdir"}="$moiraidir/$execid";
		$vars->{"tmpdir"}="$moiraidir/$execid/tmp";
		$vars->{"stderrfile"}="$workdir/stderr.txt";
		$vars->{"stdoutfile"}="$workdir/stdout.txt";
		system("ssh $username\@$server 'mkdir -p $workdir'");
		uploadIfNecessary("rdf.pl","$username\@$server:$homedir/rdf.pl");
		uploadIfNecessary("moirai2.pl","$username\@$server:$homedir/moirai2.pl");
		my $container=$command->{$urls->{"daemon/container"}};
		if(defined($container)){
			$vars->{"rootdir"}="/root";
			$vars->{"bashfile"}="/root/$moiraidir/$execid/run.sh";
			if($container=~/\.sif$/){#singularity
				uploadIfNecessary($container,"$username\@$server:$homedir/$container");
			}else{#docker
				#system("docker save $container > $container.tar");
				#uploadIfNecessary("$containert.tar","$username\@$server:$homedir/$container.tar");
			}
		}
		$workdir="$username\@$server:$workdir";
	}elsif(exists($command->{$urls->{"daemon/container"}})){
		$vars->{"rootdir"}="/root";
		$vars->{"bashfile"}="/root/$workdir/run.sh";
	}
	return $workdir;
}
############################## jsonDecode ##############################
sub jsonDecode{
	my $text=shift();
	my @temp=split(//,$text);
	my $chars=\@temp;
	my $index=0;
	my $value;
	if($chars->[$index] eq "["){($value,$index)=toJsonArray($chars,$index+1);return $value;}
	elsif($chars->[$index] eq "{"){($value,$index)=toJsonHash($chars,$index+1);return $value;}
}
sub toJsonArray{
	my $chars=shift();
	my $index=shift();
	my $array=[];
	my $value;
	my $length=scalar(@{$chars});
	for(;$chars->[$index] ne "]"&&$index<$length;$index++){
		if($chars->[$index] eq "["){($value,$index)=toJsonArray($chars,$index+1);push(@{$array},$value);}
		elsif($chars->[$index] eq "{"){($value,$index)=toJsonHash($chars,$index+1);push(@{$array},$value);}
		elsif($chars->[$index] eq "\""){($value,$index)=toJsonStringDoubleQuote($chars,$index+1);push(@{$array},$value);}
		elsif($chars->[$index] eq "\'"){($value,$index)=toJsonStringSingleQuote($chars,$index+1);push(@{$array},$value);}
	}
	return ($array,$index);
}
sub toJsonHash{
	my $chars=shift();
	my $index=shift();
	my $hash={};
	my $key;
	my $value;
	my $length=scalar(@{$chars});
	for(my $findKey=1;$index<$length;$index++){
		if($chars->[$index] eq "}"){
			if(defined($value)){$hash->{$key}=$value;}
			last;
		}elsif($findKey==1){
			if($value ne ""){$hash->{$key}=$value;$value="";}
			if($chars->[$index] eq ":"){$key=chomp($key);$findKey=0;}
			elsif($chars->[$index] eq "\""){($key,$index)=toJsonStringDoubleQuote($chars,$index+1);$findKey=0;}
			elsif($chars->[$index] eq "\'"){($key,$index)=toJsonStringSingleQuote($chars,$index+1);$findKey=0;}
			elsif($chars->[$index]!~/^\s$/){$key.=$chars->[$index];}
		}else{
			if($chars->[$index] eq ":"){next;}
			elsif($chars->[$index] eq ","){$findKey=1;}
			elsif($chars->[$index] eq "["){($value,$index)=toJsonArray($chars,$index+1);$hash->{$key}=$value;$value=undef;}
			elsif($chars->[$index] eq "{"){($value,$index)=toJsonHash($chars,$index+1);$hash->{$key}=$value;$value=undef;}
			elsif($chars->[$index] eq "\""){($value,$index)=toJsonStringDoubleQuote($chars,$index+1);$hash->{$key}=$value;$value=undef;}
			elsif($chars->[$index] eq "\'"){($value,$index)=toJsonStringSingleQuote($chars,$index+1);$hash->{$key}=$value;$value=undef;}
			elsif($chars->[$index]!~/^\s$/){$value.=$chars->[$index];}
		}
	}
	return ($hash,$index);
}
sub toJsonStringDoubleQuote{
	my $chars=shift();
	my $index=shift();
	my $length=scalar(@{$chars});
	my $value;
	my $i;
	for($i=$index;$i<$length;$i++){
		if($chars->[$i] eq "\""){
			if($i==$index){last;}
			elsif($chars->[$i-1] ne "\\"){last;}
		}
		$value.=$chars->[$i];
	}
	return (jsonUnescape($value),$i);
}
sub toJsonStringSingleQuote{
	my $chars=shift();
	my $index=shift();
	my $length=scalar(@{$chars});
	my $value;
	my $i;
	for($i=$index;$i<$length;$i++){
		if($chars->[$i] eq "\'"){
			if($i==$index){last;}
			elsif($chars->[$i-1] ne "\\"){last;}
		}
		$value.=$chars->[$i];
	}
	return (jsonUnescape($value),$i);
}
sub jsonUnescape{
	my $text=shift();
	$text=~s/\\\\/#_ESCAPED_#/g;
	$text=~s/\\"/\"/g;
	$text=~s/\\t/\t/g;
	$text=~s/\\r/\r/g;
	$text=~s/\\n/\n/g;
	$text=~s/#_ESCAPED_#/\\/g;
	return $text;
}
############################## jsonEncode ##############################
sub jsonEncode{
	my $object=shift;
	if(ref($object) eq "ARRAY"){return jsonEncode_array($object);}
	elsif(ref($object) eq "HASH"){return jsonEncode_hash($object);}
	else{return "\"".json_escape($object)."\"";}
}
sub jsonEncode_array{
	my $hashtable=shift();
	my $json="[";
	my $i=0;
	foreach my $object(@{$hashtable}){
		if($i>0){$json.=",";}
		$json.=jsonEncode($object);
		$i++;
	}
	$json.="]";
	return $json;
}
sub jsonEncode_hash{
	my $hashtable=shift();
	my $json="{";
	my $i=0;
	foreach my $subject (sort{$a cmp $b} keys(%{$hashtable})){
		if($i>0){$json.=",";}
		$json.="\"$subject\":".jsonEncode($hashtable->{$subject});
		$i++;
	}
	$json.="}";
	return $json;
}
sub json_escape{
	my $text=shift();
	$text=~s/\\/\\\\/g;
	$text=~s/\n/\\n/g;
	$text=~s/\r/\\r/g;
	$text=~s/\t/\\t/g;
	$text=~s/\"/\\"/g;
	return $text;
}
############################## linecount ##############################
sub linecount{
	my $path=shift();
	if(!(-f $path)){return 0;}
	elsif($path=~/\.gz(ip)?$/){my $count=`gzip -cd $path|wc -l`;chomp($count);return $count;}
	elsif($path=~/\.bz(ip)?2$/){my $count=`bzip2 -cd $path|wc -l`;chomp($count);return $count;}
	elsif($path=~/\.bam$/){my $count=`samtools view $path|wc -l`;chomp($count);return $count;}
	else{my $count=`cat $path|wc -l`;if($count=~/(\d+)/){$count=$1;};return $count;}
}
############################## listFiles ##############################
sub listFiles{
	my @input_directories=@_;
	my $file_suffix=shift(@input_directories);
	my @input_files=();
	foreach my $input_directory (@input_directories){
		if(-f $input_directory){push(@input_files,$input_directory);next;}# It's a file, so process file
		elsif(-l $input_directory){push(@input_files,$input_directory);next;}# It's a file, so process file
		opendir(DIR,$input_directory);
		foreach my $file(readdir(DIR)){
			if($file eq "."){next;}
			if($file eq "..") {next;}
			if($file eq ""){next;}
			$file="$input_directory/$file";
			if(-d $file){next;}
			elsif($file!~/$file_suffix$/){next;}
			push(@input_files,$file);
		}
		closedir(DIR);
	}
	return sort{$a cmp $b}@input_files;
}
############################## listFilesRecursively ##############################
sub listFilesRecursively{
	my @directories=@_;
	my $filegrep=shift(@directories);
	my $fileungrep=shift(@directories);
	my $recursivesearch=shift(@directories);
	my @inputfiles=();
	foreach my $directory (@directories){
		$directory=Cwd::abs_path($directory);
		if(-f $directory){push(@inputfiles,$directory);next;}
		elsif(-l $directory){push(@inputfiles,$directory);next;}
		opendir(DIR,$directory);
		foreach my $file(readdir(DIR)){
			if($file eq "."){next;}
			if($file eq ".."){next;}
			if($file eq ""){next;}
			if($file=~/^\./){next;}
			my $path="$directory/$file";
			if(-d $path){
				if($recursivesearch!=0){push(@inputfiles,listFilesRecursively($filegrep,$fileungrep,$recursivesearch-1,$path));}
				next;
			}
			if(defined($filegrep)&&$file!~/$filegrep/){next;}
			if(defined($fileungrep)&&$file=~/$fileungrep/){next;}
			push(@inputfiles,$path);
		}
		closedir(DIR);
	}
	return sort{$a cmp $b}@inputfiles;
}
############################## listLogs ##############################
sub listLogs{
	my @logDirs=();
	opendir(DIR,"$moiraidir/log");
	foreach my $filename(readdir(DIR)){
		if($filename eq "."){next;}
		if($filename eq ".."){next;}
		if($filename eq ""){next;}
		if($filename!~/\d{8}/){next;}
		my $path="$moiraidir/log/$filename";
		if(!-d $path){next;}
		push(@logDirs,$path);
	}
	closedir(DIR);
	my @logFiles=();
	foreach my $logDir(@logDirs){push(@logFiles,listFiles("txt",$logDir));}
	return sort{$a cmp $b}@logFiles;
}
############################## listMoirais ##############################
sub listMoirais{
	my @input_directories=@_;
	my @moiraiDirs=();
	foreach my $input_directory(@input_directories){
		if(-d "$input_directory/automate"){push(@moiraiDirs,$input_directory);}
		elsif(-d "$input_directory/ctrl"){push(@moiraiDirs,$input_directory);}
		elsif(-f $input_directory && $input_directory=~/\.sh$/){push(@moiraiDirs,$input_directory);next;}
		elsif(-l $input_directory && $input_directory=~/\.sh$/){push(@moiraiDirs,$input_directory);next;}
		opendir(DIR,$input_directory);
		foreach my $file(readdir(DIR)){	
			if($file eq "."){next;}
			if($file eq "..") {next;}
			if($file eq ""){next;}
			if(! -d "$input_directory/$file"){next;}
			if(-d "$input_directory/$file/automate"){push(@moiraiDirs,"$input_directory/$file");}
			elsif(-d "$input_directory/$file/ctrl"){push(@moiraiDirs,"$input_directory/$file");}
		}
		closedir(DIR);
	}
	foreach my $moiraiDir(@moiraiDirs){if($moiraiDir=~/^\.\/(\S+)$/){$moiraiDir=$1;}}# remove ./
	return sort{$a cmp $b}@moiraiDirs;
}
############################## loadCommandFromURL ##############################
sub loadCommandFromURL{
	my $url=shift();
	my $commands=shift();
	if(exists($commands->{$url})){return $commands->{$url};}
	if(defined($opt_l)){print STDERR "#Loading $url:\t";}
	my $command=($url=~/\.json$/)?getJson($url):getBash($url);
	if(scalar(keys(%{$command}))==0){print "ERROR: Couldn't load $url\n";exit(1);}
	loadCommandFromURLSub($command,$url);
	$command->{$urls->{"daemon/command"}}=$url;
	if(defined($opt_l)){print STDERR "OK\n";}
	$commands->{$url}=$command;
	return $command;
}
sub loadCommandFromURLSub{
	my $command=shift();
	my $url=shift();
	$command->{"input"}=[];
	$command->{"output"}=[];
	my $default={};
	if(exists($command->{$urls->{"daemon/inputs"}})){
		$command->{$urls->{"daemon/inputs"}}=handleArray($command->{$urls->{"daemon/inputs"}},$default);
		$command->{"inputs"}=handleHash(@{$command->{$urls->{"daemon/inputs"}}});
		if(!exists($command->{$urls->{"daemon/input"}})){$command->{$urls->{"daemon/input"}}=$command->{$urls->{"daemon/inputs"}};}
	}
	if(exists($command->{$urls->{"daemon/input"}})){
		$command->{$urls->{"daemon/input"}}=handleArray($command->{$urls->{"daemon/input"}},$default);
		my @array=();
		foreach my $input(@{$command->{$urls->{"daemon/input"}}}){push(@array,$input);}
		if(exists($command->{$urls->{"daemon/inputs"}})){
			my $hash=handleHash(@{$command->{$urls->{"daemon/input"}}});
			foreach my $input(@{$command->{"daemon/inputs"}}){if(!exists($hash->{$input})){push(@array,$input);}}
		}
		$command->{"input"}=\@array;
	}
	if(exists($command->{$urls->{"daemon/command/option"}})){
		my $hash={};
		while(my ($key,$val)=each(%{$command->{$urls->{"daemon/command/option"}}})){
			if($key=~/^\$(.+)$/){$key=$1}
			$hash->{$key}=$val;
		}
		$command->{"options"}=$hash;
	}
	if(exists($command->{$urls->{"daemon/return"}})){
		$command->{$urls->{"daemon/output"}}=handleArray($command->{$urls->{"daemon/output"}},$default);
		my $hash=handleHash(@{$command->{$urls->{"daemon/output"}}});
		my $returnvalue=$command->{$urls->{"daemon/return"}};
		if(!exists($hash->{$returnvalue})){push(@{$command->{$urls->{"daemon/output"}}},$returnvalue);}
	}
	if(exists($command->{$urls->{"daemon/output"}})){
		$command->{$urls->{"daemon/output"}}=handleArray($command->{$urls->{"daemon/output"}},$default);
		my @array=();
		foreach my $output(@{$command->{$urls->{"daemon/output"}}}){push(@array,$output);}
		$command->{"output"}=\@array;
	}
	my @array=();
	foreach my $input(@{$command->{"input"}}){push(@array,$input);}
	foreach my $output(@{$command->{"output"}}){push(@array,$output);}
	$command->{"keys"}=\@array;
	if(exists($command->{$urls->{"daemon/return"}})){$command->{$urls->{"daemon/return"}}=removeDollar($command->{$urls->{"daemon/return"}});}
	if(exists($command->{$urls->{"daemon/unzip"}})){$command->{$urls->{"daemon/unzip"}}=handleArray($command->{$urls->{"daemon/unzip"}});}
	if(exists($command->{$urls->{"daemon/file/stats"}})){$command->{$urls->{"daemon/file/stats"}}=removeDollar($command->{$urls->{"daemon/file/stats"}});}
	if(exists($command->{$urls->{"daemon/file/md5"}})){$command->{$urls->{"daemon/file/md5"}}=handleArray($command->{$urls->{"daemon/file/md5"}});}
	if(exists($command->{$urls->{"daemon/file/filesize"}})){$command->{$urls->{"daemon/file/filesize"}}=handleArray($command->{$urls->{"daemon/file/filesize"}});}
	if(exists($command->{$urls->{"daemon/file/linecount"}})){$command->{$urls->{"daemon/file/linecount"}}=handleArray($command->{$urls->{"daemon/file/linecount"}});}
	if(exists($command->{$urls->{"daemon/file/seqcount"}})){$command->{$urls->{"daemon/file/seqcount"}}=handleArray($command->{$urls->{"daemon/file/seqcount"}});}
	if(exists($command->{$urls->{"daemon/description"}})){$command->{$urls->{"daemon/description"}}=handleArray($command->{$urls->{"daemon/description"}});}
	if(exists($command->{$urls->{"daemon/bash"}})){$command->{"bashCode"}=handleCode($command->{$urls->{"daemon/bash"}});}
	if(!exists($command->{$urls->{"daemon/maxjob"}})){$command->{$urls->{"daemon/maxjob"}}=1;}
	if(exists($command->{$urls->{"daemon/script"}})){handleScript($command);}
	if(exists($command->{$urls->{"daemon/error/file/empty"}})){$command->{$urls->{"daemon/error/file/empty"}}=handleHash(@{handleArray($command->{$urls->{"daemon/error/file/empty"}})});}
	if(exists($command->{$urls->{"daemon/error/stderr/ignore"}})){$command->{$urls->{"daemon/error/stderr/ignore"}}=handleArray($command->{$urls->{"daemon/error/stderr/ignore"}});}
	if(exists($command->{$urls->{"daemon/error/stdout/ignore"}})){$command->{$urls->{"daemon/error/stdout/ignore"}}=handleArray($command->{$urls->{"daemon/error/stdout/ignore"}});}
	if(scalar(keys(%{$default}))>0){$command->{"default"}=$default;}
}
############################## loadLogs ##############################
sub loadLogs{
	my @files=listFiles(".txt\$",undef,-1,$jobdir);
	my $hash={};
	foreach my $file(@files){
		my $basename=basename($file,".txt");
		$hash->{$basename}={};
		my $reader=openFile($file);
		while(<$reader>){
			chomp;
			if(/^========================================/){next;}
			my ($key,$val)=split(/\t/);
			$hash->{$basename}->{$key}=$val;
		}
		close($reader);
	}
	return $hash;
}
############################## loadExecutes ##############################
sub loadExecutes{
	my $commands=shift();
	my $executes=shift();
	my $execurls=shift();
	my $newjob=0;
	my @files=listFiles(".txt\$",undef,-1,$jobdir);
	foreach my $file(@files){
		my $id=basename($file,".txt");
		my $hash={};
		my $reader=openFile($file);
		while(<$reader>){
			chomp;
			if(/^========================================/){next;}
			my ($key,$val)=split(/\t/);
			$hash->{$key}=$val;
		}
		close($reader);
		if(exists($hash->{$urls->{"daemon/execute"}})){next;}
		$newjob++;
		my $url=$hash->{$urls->{"daemon/command"}};
		loadCommandFromURL($url,$commands);
		if(!existsArray($execurls,$url)){push(@{$execurls},$url);}
		if(exists($executes->{$url}->{$id})){next;}
		$executes->{$url}->{$id}={};
		$executes->{$url}->{$id}->{"cmdurl"}=$url;
		$executes->{$url}->{$id}->{"execid"}=$id;
		while(my ($key,$val)=each(%{$hash})){
			if($key=~/^$url#(.+)$/){
				$key=$1;
				if(!exists($executes->{$url}->{$id}->{$key})){$executes->{$url}->{$id}->{$key}=$val;}
				elsif(ref($executes->{$url}->{$id}->{$key})eq"ARRAY"){push(@{$executes->{$url}->{$id}->{$key}},$val);}
				else{$executes->{$url}->{$id}->{$key}=[$executes->{$url}->{$id}->{$key},$val]}
			}
		}
	}
	return $newjob;
}
############################## ls ##############################
sub ls{
	my @directories=@_;
	my $queryResults;
	if(defined($opt_i)){
		my $query=$opt_i;
		while(my($key,$val)=each(%{$userdefined})){$query=~s/\$$key/$val/g;}
		if(checkInputOutput($query)){$queryResults=getQueryResults($dbdir,$query);}
	}elsif(scalar(@directories)==0){push(@directories,".");}
	if(scalar(@directories)>0){
		foreach my $directory(@directories){push(@{$queryResults->[1]},{"input"=>$directory});}
		my $tmp={"input"=>1};
		foreach my $key(@{$queryResults->[0]}){$tmp->{$key}=1;}
		my @array=keys(%{$tmp});
		$queryResults->[0]=\@array;
	}
	my $keys=$queryResults->[0];
	my $values=$queryResults->[1];
	my @lines=();
	my $template=defined($opt_o)?$opt_o:"\$path";
	my @templates=split(/,/,$template);
	foreach my $value(@{$values}){
		my $val=$value->{"input"};
		my @files=listFilesRecursively($opt_g,$opt_G,$opt_r,$val);
		foreach my $file(@files){
			foreach my $template(@templates){
				my $line=$template;
				my $hash=basenames($file);
				$hash=fileStats($file,$line,$hash);
				while(my($k,$v)=each(%{$value})){
					$line=~s/\$\{$k\}/$v/g;
					$line=~s/\$$k/$v/g;
				}
				$line=~s/\\t/\t/g;
				$line=~s/\-\>/\t/g;
				$line=~s/\\n/\n/g;
				while(my($k,$v)=each(%{$hash})){
					$line=~s/\$\{$k\}/$v/g;
					$line=~s/\$$k/$v/g;
				}
				push(@lines,$line);
			}
		}
	}
	if(!defined($opt_o)||defined($opt_l)){foreach my $line(@lines){print "$line\n";}return;}
	my ($writer,$temp)=tempfile(UNLINK=>1);
	foreach my $line(@lines){print $writer "$line\n";}
	close($writer);
	system("perl $prgdir/rdf.pl -q -d $moiraidir import < $temp");
}
############################## mainProcess ##############################
sub mainProcess{
	my $execurls=shift();
	my $commands=shift();
	my $executes=shift();
	my $processes=shift();
	my $available=shift();
	my $thrown=0;
	for(my $i=0;($i<$available)&&(scalar(@{$execurls})>0);$i++){
		my $url=shift(@{$execurls});
		my $command=$commands->{$url};
		my $singlethread=(exists($command->{$urls->{"daemon/singlethread"}})&&$command->{$urls->{"daemon/singlethread"}} eq "true");
		my $qjobopt=$command->{$urls->{"daemon/qjobopt"}};
		my $maxjob=$command->{$urls->{"daemon/maxjob"}};
		if(!defined($maxjob)){$maxjob=1;}
		my @variables=();
		if(exists($command->{$urls->{"daemon/bash"}})){
			foreach my $execid(sort{$a cmp $b}keys(%{$executes->{$url}})){
				if(!$singlethread&&$maxjob<=0){last;}
				my $vars=$executes->{$url}->{$execid};
				my $workdir=initExecute($dbdir,$command,$vars);
				bashCommand($command,$vars);
				push(@variables,$vars);
				delete($executes->{$url}->{$execid});
				my $datetime=`date +%s`;chomp($datetime);
				writeLog($execid,$urls->{"daemon/execute"}."\tregistered",$urls->{"daemon/timeregistered"}."\t$datetime",$urls->{"daemon/workdir"}."\t$workdir",$urls->{"daemon/execid"}."\t$execid");
				$maxjob--;
				$thrown++;
			}
		}
		if(defined($opt_p)){
			foreach my $var(@variables){
				my $bashsrc=$var->{"bashsrc"};
				my $execid=$var->{"execid"};
				my $logfile="$jobdir/$execid.txt";
				open(IN,$bashsrc);
				while(<IN>){print}
				close(IN);
				unlink($bashsrc);
				unlink($logfile);
				rmdir("$moiraidir/$execid");
			}
		}else{
			throwJobs($url,$command,$processes,@variables);
		}
		if(scalar(keys(%{$executes->{$url}}))>0){unshift(@{$execurls},$url);}
	}
	return $thrown;
}
############################## mkdirs ##############################
sub mkdirs{
	my @directories=@_;
	foreach my $directory(@directories){
		if(-d $directory){next;}
		my @tokens=split(/[\/\\]/,$directory);
		if(($tokens[0] eq "")&&(scalar(@tokens)>1)){
			shift(@tokens);
			my $token=shift(@tokens);
			unshift(@tokens,"/$token");
		}
		my $string="";
		foreach my $token(@tokens){
			$string.=(($string eq "")?"":"/").$token;
			if(-d $string){next;}
			if(!mkdir($string)){return 0;}
		}
	}
	return 1;
}
############################## openFile ##############################
sub openFile{
	my $path=shift();
	if($path=~/^(.+\@.+)\:(.+)$/){
		if($path=~/\.gz(ip)?$/){return IO::File->new("ssh $1 'gzip -cd $2'|");}
		elsif($path=~/\.bz(ip)?2$/){return IO::File->new("ssh $1 'bzip2 -cd $2'|");}
		elsif($path=~/\.bam$/){return IO::File->new("ssh $1 'samtools view $2'|");}
		else{return IO::File->new("ssh $1 'cat $2'|");}
	}else{
		if($path=~/\.gz(ip)?$/){return IO::File->new("gzip -cd $path|");}
		elsif($path=~/\.bz(ip)?2$/){return IO::File->new("bzip2 -cd $path|");}
		elsif($path=~/\.bam$/){return IO::File->new("samtools view $path|");}
		else{return IO::File->new($path);}
	}
}
############################## printCommand ##############################
sub printCommand{
	my $url=shift();
	my $commands=shift();
	my $command=loadCommandFromURL($url,$commands);
	my @inputs=@{$command->{$urls->{"daemon/input"}}};
	my @outputs=@{$command->{$urls->{"daemon/output"}}};
	print STDOUT "\n#URL     :".$command->{$urls->{"daemon/command"}}."\n";
	my $line="#Command :".basename($command->{$urls->{"daemon/command"}});
	if(scalar(@inputs)>0){$line.=" [".join("] [",@inputs)."]";}
	if(scalar(@outputs)>0){$line.=" [".join("] [",@outputs)."]";}
	print STDOUT "$line\n";
	if(scalar(@inputs)>0){print STDOUT "#Input   :".join(", ",@{$command->{"input"}})."\n";}
	if(scalar(@outputs)>0){print STDOUT "#Output  :".join(", ",@{$command->{"output"}})."\n";}
	print STDOUT "#Bash    :";
	if(ref($command->{$urls->{"daemon/bash"}}) ne "ARRAY"){print STDOUT $command->{$urls->{"daemon/bash"}}."\n";}
	else{my $index=0;foreach my $line(@{$command->{$urls->{"daemon/bash"}}}){if($index++>0){print STDOUT "         :"}print STDOUT "$line\n";}}
	if(exists($command->{$urls->{"daemon/description"}})){print STDOUT "#Summary :".join(", ",@{$command->{$urls->{"daemon/description"}}})."\n";}
	if($command->{$urls->{"daemon/maxjob"}}>1){print STDOUT "#Maxjob  :".$command->{$urls->{"daemon/maxjob"}}."\n";}
	if(exists($command->{$urls->{"daemon/singlethread"}})){print STDOUT "#Single  :".($command->{$urls->{"daemon/singlethread"}}?"true":"false")."\n";}
	if(exists($command->{$urls->{"daemon/qjobopt"}})){print STDOUT "#qjobopt :".$command->{$urls->{"daemon/qjobopt"}}."\n";}
	if(exists($command->{$urls->{"daemon/script"}})){
		foreach my $script(@{$command->{$urls->{"daemon/script"}}}){
			print STDOUT "#Script  :".$script->{$urls->{"daemon/script/name"}}."\n";
			foreach my $line(@{$script->{$urls->{"daemon/script/code"}}}){
				print STDOUT "         :$line\n";
			}
		}
	}
	print STDOUT "\n";
}
############################## printRows ##############################
sub printRows{
	my $keys=shift();
	my $hashtable=shift();
	my @lengths=();
	my @labels=();
	foreach my $key(@{$keys}){push(@labels,"\$$key");}
	my $indexlength=length("".scalar(@{$hashtable}));
	for(my $i=0;$i<scalar(@labels);$i++){$lengths[$i]=length($labels[$i]);}
	for(my $i=0;$i<scalar(@{$hashtable});$i++){
		my $hash=$hashtable->[$i];
		for(my $j=0;$j<scalar(@labels);$j++){
			my $length=length($hash->{$keys->[$j]});
			if($lengths[$j]<$length){$lengths[$j]=$length;}
		}
	}
	my $tableline="+";
	for(my $i=0;$i<$indexlength;$i++){$tableline.="-"}
	for(my $i=0;$i<scalar(@lengths);$i++){
		$tableline.="+";
		for(my $j=0;$j<$lengths[$i];$j++){$tableline.="-";}
	}
	$tableline.="+";
	print STDERR "$tableline\n";
	my $labelline="|";
	for(my $i=0;$i<$indexlength;$i++){$labelline.=" "}
	for(my $i=0;$i<scalar(@labels);$i++){
		my $label=$labels[$i];
		my $l=length($label);
		$labelline.="|";
		my $string=$label;
		for(my $j=$l;$j<$lengths[$i];$j++){if(($j-$l)%2==0){$string.=" ";}else{$string=" $string";}}
		$labelline.=$string;
	}
	$labelline.="|";
	print STDERR "$labelline\n";
	print STDERR "$tableline\n";
	for(my $i=0;$i<scalar(@{$hashtable});$i++){
		my $hash=$hashtable->[$i];
		my $line=$i+1;
		my $l=length($line);
		for(my $j=$l;$j<$indexlength;$j++){$line=" $line";}
		$line="|$line";
		for(my $j=0;$j<scalar(@{$keys});$j++){
			my $token=$hash->{$keys->[$j]};
			my $l=length($token);
			$line.="|$token";
			for(my $k=$l;$k<$lengths[$j];$k++){$line.=" ";}
		}
		$line.="|";
		print STDERR "$line\n";
	}
	print STDERR "$tableline\n";
}
############################## printTable ##############################
sub printTable{
	my @out=@_;
	my $return_type=$out[0];
	if(lc($return_type) eq "print"){$return_type=0;shift(@out);}
	elsif(lc($return_type) eq "array"){$return_type=1;shift(@out);}
	elsif(lc($return_type) eq "stderr"){$return_type=2;shift(@out);}
	else{$return_type= 2;}
	printTableSub($return_type,"",@out);
}
sub printTableSub{
	my @out=@_;
	my $return_type=shift(@out);
	my $string=shift(@out);
	my @output=();
	for(@out){
		if(ref( $_ ) eq "ARRAY"){
			my @array=@{$_};
			my $size=scalar(@array);
			if($size==0){
				if($return_type==0){print $string."[]\n";}
				elsif($return_type==1){push(@output,$string."[]");}
				elsif($return_type==2){print STDERR $string."[]\n";}
			}else{
				for(my $i=0;$i<$size;$i++){push(@output,printTableSub($return_type,$string."[$i]=>\t",$array[$i]));}
			}
		} elsif(ref($_)eq"HASH"){
			my %hash=%{$_};
			my @keys=sort{$a cmp $b}keys(%hash);
			my $size=scalar(@keys);
			if($size==0){
				if($return_type==0){print $string."{}\n";}
				elsif($return_type==1){push( @output,$string."{}");}
				elsif($return_type==2){print STDERR $string."{}\n";}
			}else{
				foreach my $key(@keys){push(@output,printTableSub($return_type,$string."{$key}=>\t",$hash{$key}));}
			}
		}elsif($return_type==0){print "$string\"$_\"\n";}
		elsif($return_type==1){push( @output,"$string\"$_\"");}
		elsif($return_type==2){print STDERR "$string\"$_\"\n";}
	}
	return wantarray?@output:$output[0];
}
############################## progress ##############################
sub progress{
	my $logs=readLogs(listLogs());
	my @files=getFiles("$ctrldir/submit");
	foreach my $file(@files){
		my $basename=basename($file,".txt");
		my $hash={};
		my @stats=stat($file);
		my $modtime=$stats[9];
		$hash->{"time"}=getDate("/",$modtime)." ".getTime(":",$modtime);
		$hash->{"execute"}="submitted";
		open(IN,$file);
		while(<IN>){
			chomp;
			my ($key,$val)=split(/\t/);
			if(!exists($hash->{$key})){$hash->{$key}=$val;}
			elsif(ref($hash->{$key}) eq "ARRAY"){push(@{$hash->{$key}},$val);}
			else{$hash->{$key}=[$hash->{$key},$val];}
		}
		close(IN);
		$logs->{$basename}=$hash;
	}
	my @json=();
	foreach my $id(sort{$a cmp $b}keys(%{$logs})){
		my $hash=$logs->{$id};
		push(@json,$hash);
	}
	print jsonEncode(\@json)."\n";
}
############################## promptCommandInput ##############################
sub promptCommandInput{
	my $command=shift();
	my $variables=shift();
	my $label=shift();
	print STDOUT "#Input: $label";
	my $default;
	if(exists($command->{"default"})&&exists($command->{"default"}->{$label})){
		$default=$command->{"default"}->{$label};
		print STDOUT " [$default]";
	}
	print STDOUT "? ";
	my $value=<STDIN>;
	chomp($value);
	if($value=~/^(.+) +$/){$value=$1;}
	if($value eq ""){if(defined($default)){$value=$default;}else{exit(1);}}
	$variables->{$label}=$value;
}
############################## readLogs ##############################
sub readLogs{
	my @logFiles=@_;
	my $hash={};
	foreach my $logFile(@logFiles){
		my $basename=basename($logFile,".txt");
		$hash->{$basename}={};
		$hash->{$basename}->{"logfile"}=$logFile;
		open(IN,$logFile);
		while(<IN>){
			chomp;
			my ($key,$val)=split(/\t/);
			if($key=~/https\:\/\/moirai2\.github\.io\/schema\/daemon\/(.+)$/){
				$key=$1;
				if($key eq "timeregistered"){$key="time";$val=getDate("/",$val)." ".getTime(":",$val);}
				if($key eq "timestarted"){$key="time";$val=getDate("/",$val)." ".getTime(":",$val)}
				if($key eq "timeended"){$key="time";$val=getDate("/",$val)." ".getTime(":",$val)}
				$hash->{$basename}->{$key}=$val;
			}
		}
		close(IN);
	}
	return $hash;
}
############################## readText ##############################
sub readText{
	my $file=shift();
	my $text="";
	open(IN,$file);
	while(<IN>){s/\r//g;$text.=$_;}
	close(IN);
	return $text;
}
############################## reloadJobsRunning ##############################
sub reloadJobsRunning{
	my @files=getFiles("$ctrldir/process");
	my $processes={};
	foreach my $file(@files){
		my $execid=basename($file,".txt");
		open(IN,$file);
		$processes->{$execid}={};
		while(<IN>){
			chomp;
			my ($key,$value)=split(/\t/);
			$processes->{$execid}->{$key}=$value;
		}
		close(IN);
	}
	return $processes;
}
############################## removeDirs ##############################
sub removeDirs{
	my @dirs=@_;
	foreach my $dir(@dirs){
		if($dir=~/^(.+\@.+)\:(.+)$/){system("ssh $1 'rmdir $2'");}
		else{rmdir($dir);}
	}
}
############################## removeDollar ##############################
sub removeDollar{
	my $value=shift();
	if($value=~/^\$(.+)$/){return $1;}
	return $value;
}
############################## removeFiles ##############################
sub removeFiles{
	my @files=@_;
	foreach my $file(@files){
		if($file=~/^(.+\@.+)\:(.+)$/){system("ssh $1 'rm $2'");}
		else{unlink($file);}
	}
}
############################## removeUnnecessaryExecutes ##############################
sub removeUnnecessaryExecutes{
	my $inputs=shift();
	my $query=shift();
	my $outputs=getQueryResults($dbdir,$query);
	my $keys=handleInputOutput($query);
	my $inputKeys={};
	foreach my $input(@{$inputs->[0]}){$inputKeys->{$input}=1;}
	my $outputKeys={};
	foreach my $output(@{$outputs->[0]}){if(!exists($inputKeys->{$output})){$outputKeys->{$output}=1;}}
	my @array=();
	foreach my $input(@{$inputs->[1]}){
		my $skip=0;
		foreach my $output(@{$outputs->[1]}){
			my $hit=1;
			foreach my $key(@{$outputs->[0]}){
				if(exists($outputKeys->{$key})){next;}
				if(!exists($input->{$key})){$hit=0;last;}
				if($input->{$key} ne $output->{$key}){$hit=0;last;}
			}
			if($hit==1){$skip=1;}
		}
		if($skip==0){push(@array,$input);}
	}
	$inputs->[1]=\@array;
}
############################## replaceStringWithHash ##############################
sub replaceStringWithHash{
	my $hash=shift();
	my $string=shift();
	my @keys=sort{length($b)<=>length($a)}keys(%{$hash});
	foreach my $key(@keys){my $value=$hash->{$key};$key="\\\$$key";$string=~s/$key/$value/g;}
	return $string;
}
############################## returnResult ##############################
sub returnResult{
	my $execid=shift();
	my $match=shift();
	my $file=getFileFromExecid($execid);
	my $reader=openFile($file);
	if($match eq "stdout"||$match eq "stderr"){
		my $flag=0;
		while(<$reader>){
			chomp;
			if(/^\#{40} (.+) \#{40}$/){if($1 eq $match){$flag=1;}else{$flag=0;}}
			elsif($flag==1){print "$_\n";}
		}
	}else{
		my $flag=0;
		my @results=();
		while(<$reader>){
			chomp;
			if(/^\#{40} (.+) \#{40}$/){if($execid eq $1){$flag=1;}else{$flag=0;}}
			if($flag){
				my ($key,$val)=split(/\t/);
				if($key eq $match){push(@results,$val);}
			}
		}
		if(scalar(@results)==0){return;}
		print join(" ",@results)."\n";
	}
}

############################## sandbox ##############################
sub sandbox{
	my @lines=@_;
	my $center=shift(@lines);
	my $length=0;
	foreach my $line(@lines){my $l=length($line);if($l>$length){$length=$l;}}
	my $label="";
	for(my $i=0;$i<$length+4;$i++){$label.="#";}
	print STDERR "$label\n";
	foreach my $line(@lines){
		for(my $i=length($line);$i<$length;$i++){
			if($center){if(($i%2)==0){$line.=" ";}else{$line=" $line";}}
			else{$line.=" ";}
		}
		print STDERR "# $line #\n";
	}
	print STDERR "$label\n";
}
############################## scriptCodeForBash ##############################
sub scriptCodeForBash{
	my @codes=@_;
	my @output=();
	for(my $i=0;$i<scalar(@codes);$i++){
		my $line=$codes[$i];
		$line=~s/\\/\\\\/g;
		$line=~s/\n/\\n/g;
		$line=~s/\$/\\\$/g;
		$line=~s/\`/\\`/g;
		push(@output,$line);
	}
	return @output;
}
############################## selectRDF ##############################
sub selectRDF{
	my $subject=shift();
	my $predicate=shift();
	my $object=shift();
	my @results=`perl $prgdir/rdf.pl -d $moiraidir select '$subject' '$predicate' '$object'`;
	foreach my $result(@results){
		chomp($result);
		my @tokens=split(/\t/,$result);
		$result=\@tokens;
	}
	return @results;
}
############################## seqcount ##############################
sub seqcount{
	my $path=shift();
	if($path=~/\.f(ast)?a((\.gz(ip)?)|(\.bz(ip)?2))?$/){
		my $reader=openFile($path);
		my $count=0;
		while(<$reader>){if(/^\>/){$count++;}}
		close($reader);
		return $count;
	}elsif($path=~/\.f(ast)?q((\.gz(ip)?)|(\.bz(ip)?2))?$/){
		my $reader=openFile($path);
		my $count=0;
		while(<$reader>){$count++;<$reader>;<$reader>;<$reader>;}
		close($reader);
		return $count;
	}else{return 0;}
}
############################## setupInputOutput ##############################
sub setupInputOutput{
	my $insertKeys=shift();
	my $queryResults=shift();
	my $inputKeys=shift();
	my $outputKeys=shift();
	my $inputs={};
	my $outputs={};
	foreach my $token(@{$queryResults->[0]}){$inputs->{"\$$token"}=1;}
	foreach my $token(@{$insertKeys}){
		foreach my $t(@{$token}){
			if($t!~/^\$\w+$/){next;}
			if(exists($inputs->{$t})){next;}
			$outputs->{$t}=1;
		}
	}
	foreach my $key(@{$inputKeys}){if($key=~/^\$\w+$/){$inputs->{$key}=1;}else{$inputs->{"\$$key"}=1;}}
	foreach my $key(@{$outputKeys}){if($key=~/^\$\w+$/){$outputs->{$key}=1;}else{$outputs->{"\$$key"}=1;}}
	my @ins=sort{$a cmp $b}keys(%{$inputs});
	my @outs=sort{$a cmp $b}keys(%{$outputs});
	return (\@ins,\@outs);
}
############################## rsyncDirectory ##############################
sub rsyncDirectory{

}
############################## tarArchiveDirectory ##############################
sub tarArchiveDirectory{
	my $directory=shift();
	if($directory=~/^(.+)\/$/){$directory=$1;}
	my $root=dirname($directory);
	my $dir=basename($directory);
	system("rm $directory/.DS_Store");
	system("tar -C $root -czvf $directory.tgz $dir 2> /dev/null");
	system("rm -r $directory 2> /dev/null");
}
############################## tarListDirectory ##############################
sub tarListDirectory{
	my $file=shift();
	my @files=`tar -ztf $file`;
	return @files;
}
############################## test ##############################
sub test{
	mkdir(test);
	unlink("test/moirai");
	open(OUT,">test/A.json");
	print OUT "{\"https://moirai2.github.io/schema/daemon/input\":\"\$string\",\"https://moirai2.github.io/schema/daemon/bash\":[\"echo \\\"\$string\\\" > \$output\"],\"https://moirai2.github.io/schema/daemon/output\":\"\$output\"}\n";
	close(OUT);
	open(OUT,">test/B.json");
	print OUT "{\"https://moirai2.github.io/schema/daemon/input\":\"\$input\",\"https://moirai2.github.io/schema/daemon/bash\":[\"sort \$input > \$output\"],\"https://moirai2.github.io/schema/daemon/output\":\"\$output\"}\n";
	close(OUT);
	testCommand("perl moirai2.pl -d test/moirai -s 1 -r '\$output' test/A.json 'Akira Hasegawa' test/output.txt","test/output.txt");
	testCommand("cat test/output.txt","Akira Hasegawa");
	testCommand("perl $prgdir/rdf.pl -d test/moirai insert case1 '#string' 'Akira Hasegawa'","inserted 1");
	testCommand("perl moirai2.pl -d test/moirai -s 1 -i '\$id->#string->\$string' -o '\$id->#text->\$output' test/A.json '\$string' 'test/\$id.txt'","");
	testCommand("cat test/case1.txt","Akira Hasegawa");
	testCommand("perl $prgdir/rdf.pl -d test/moirai select case1 '#text'","case1\t#text\ttest/case1.txt");
	testCommand("perl moirai2.pl -d test/moirai -s 1 -i '\$id->#text->\$input' -o '\$input->#sorted->\$output' test/B.json '\$output=test/\$id.sort.txt'","");
	testCommand("cat test/case1.sort.txt","Akira Hasegawa");
	testCommand("perl $prgdir/rdf.pl -d test/moirai select % '#sorted'","test/case1.txt\t#sorted\ttest/case1.sort.txt");
	open(OUT,">test/case2.txt");print OUT "Hasegawa\nAkira\nChiyo\nHasegawa\n";close(OUT);
	testCommand("perl $prgdir/rdf.pl -d test/moirai insert case2 '#text' test/case2.txt","inserted 1");
	testCommand("perl moirai2.pl -d test/moirai -s 1 -i '\$id->#text->\$input' -o '\$input->#sorted->\$output' test/B.json '\$output=test/\$id.sort.txt'","");
	testCommand("cat test/case2.sort.txt","Akira\nChiyo\nHasegawa\nHasegawa");
	unlink("test/output.txt");
	unlink("test/case1.txt");
	unlink("test/case2.txt");
	unlink("test/case1.sort.txt");
	unlink("test/case2.sort.txt");
	unlink("test/A.json");
	unlink("test/B.json");
	open(OUT,">test/C.json");
	print OUT "{\"https://moirai2.github.io/schema/daemon/bash\":\"unamea=\$(uname -a)\",\"https://moirai2.github.io/schema/daemon/output\":\"\$unamea\"}\n";
	close(OUT);
	my $name=`uname -s`;chomp($name);
	testCommand2("perl moirai2.pl -d test/moirai -s 1 -r unamea test/C.json","^$name");
	testCommand2("perl moirai2.pl -q qsub -d test/moirai -s 1 -r unamea test/C.json","^$name");
	testCommand2("perl moirai2.pl -d test/moirai -s 1 -r unamea -c ubuntu test/C.json","^Linux");
	testCommand2("perl moirai2.pl -q qsub -d test/moirai -s 1 -r unamea -c ubuntu test/C.json","^Linux");
	unlink("test/C.json");
	open(OUT,">test/D.json");
	print OUT "{\"https://moirai2.github.io/schema/daemon/container\":\"ubuntu\",\"https://moirai2.github.io/schema/daemon/bash\":\"unamea=\$(uname -a)\",\"https://moirai2.github.io/schema/daemon/output\":\"\$unamea\"}\n";
	close(OUT);
	testCommand2("perl moirai2.pl -d test/moirai -s 1 -r unamea test/D.json","^Linux");
	testCommand2("perl moirai2.pl -q qsub -d test/moirai -s 1 -r unamea test/D.json","^Linux");
	testCommand2("perl moirai2.pl -d test/moirai -s 1 -r unamea -c ubuntu test/D.json","^Linux");
	testCommand2("perl moirai2.pl -q qsub -d test/moirai -s 1 -r unamea -c ubuntu test/D.json","^Linux");
	unlink("test/D.json");
	open(OUT,">test/moirai/ctrl/insert/A.txt");
	print OUT "A\t#name\tAkira\n";
	close(OUT);
	system("echo 'mkdir -p test/moirai/\$dirname'|perl moirai2.pl -d test/moirai -s 1 -i '\$id->#name->\$dirname' -o '\$id->#mkdir->done' command");
	if(!-e "test/moirai/Akira"){print STDERR "test/moirai/Akira directory not created";}
	open(OUT,">test/moirai/ctrl/insert/B.txt");
	print OUT "B\t#name\tBen\n";
	close(OUT);
	system("echo 'mkdir -p test/moirai/\$dirname'|perl moirai2.pl -d test/moirai -s 1 -i '\$id->#name->\$dirname' -o '\$id->#mkdir->done' command");
	if(!-e "test/moirai/Ben"){print STDERR "test/moirai/Ben directory not created";}
	testCommand("perl moirai2.pl -d test/moirai -s 1 -o 'A->B->C' assign","");
	testCommand("perl moirai2.pl -d test/moirai -s 1 exec 'ls test/moirai/ctrl'","insert\njob\nprocess\nsubmit");
	testCommand("perl moirai2.pl -d test/moirai -s 1 -r '\$output' exec 'output=(`ls test/moirai/ctrl`);'","insert job process submit");
	testCommand("perl moirai2.pl -d test/moirai -s 1 -r output exec 'ls -lt > \$output' '\$output=test/moirai/list.txt'","test/moirai/list.txt");
	testCommand("perl moirai2.pl -d test/moirai -s 1 -o 'test/moirai/ctrl->file->\$output' exec 'output=(`ls test/moirai/ctrl`);'","");
	testCommand("perl $prgdir/rdf.pl -d test/moirai select test/moirai/ctrl file","test/moirai/ctrl\tfile\tinsert\ntest/moirai/ctrl\tfile\tjob\ntest/moirai/ctrl\tfile\tprocess\ntest/moirai/ctrl\tfile\tsubmit");
	system("rm -r test/moirai");
	system("rm -r test");
}
############################## testCommand ##############################
sub testCommand{
	my $command=shift();
	my $value2=shift();
	my ($writer,$file)=tempfile(UNLINK=>1);
	close($writer);
	if(system("$command > $file")){return 1;}
	my $value1=readText($file);
	chomp($value1);
	if($value1 eq $value2){return 0;}
	print STDERR ">$command\n";
	print STDERR "$value1\n";
	print STDERR "$value2\n";
}
############################## testCommand2 ##############################
sub testCommand2{
	my $command=shift();
	my $value2=shift();
	my ($writer,$file)=tempfile(UNLINK=>1);
	close($writer);
	if(system("$command > $file")){return 1;}
	my $value1=readText($file);
	chomp($value1);
	if($value1=~/$value2/){return 0;}
	print STDERR ">$command\n";
	print STDERR "[$value1]\n";
	print STDERR "[$value2]\n";
}
############################## throwBashJob ##############################
sub throwBashJob{
	my $path=shift();
	my $qjob=shift();
	my $qjobopt=shift();
	my $stdout=shift();
	my $stderr=shift();
	my $server;
	if($path=~/^(.+\@.+)\:(.+)$/){$server=$1;$path=$2;}
	my $basename=basename($path,".sh");
	if($qjob eq "sge"){
		my $command="qsub";
		if(defined($server)){if(!defined(which("$server:$command",$cmdpaths))){print STDERR "ERROR: $command not found at $server\n";exit(1);}}
		elsif(!defined(which($command,$cmdpaths))){print STDERR "ERROR: $command not found\n";exit(1);}
		if(defined($qjobopt)){$command.=" $qjobopt";}
		$command.=" $path";
		if(defined($server)){$command="ssh $server \"$command\" 2>&1 1>/dev/null";}
		if(defined($opt_l)){print STDERR "$command\n";}
		if(system($command)==0){sleep(1);if(defined($opt_l)){print STDERR "OK\n";}}
		else{appendText("ERROR: Failed to $command",$stderr);}
	}elsif($qjob eq "slurm"){
		my $command="slurm";
		if(defined($server)){if(!defined(which("$server:$command",$cmdpaths))){print STDERR "ERROR: $command not found at $server\n";exit(1);}}
		elsif(!defined(which($command,$cmdpaths))){print STDERR "ERROR: $command not found\n";exit(1);}
		$command.=" -o $stdout\n";
		$command.=" -e $stderr\n";
		if(defined($qjobopt)){$command.=" $qjobopt";}
		$command.=" $path";
		if(defined($server)){$command="ssh $server \"$command\" 2>&1 1>/dev/null";}
		if(defined($opt_l)){print STDERR "$command\n";}
		if(system($command)==0){sleep(1);if(defined($opt_l)){print STDERR "OK\n";}}
		else{print STDERR "ERROR: Failed to $command\n";exit(1);}
	}else{
		my $command;
		if(defined($server)){$command="ssh $server \"bash $path > $stdout 2> $stderr &\"";}
		else{$command="bash $path >$stdout 2>$stderr &";}
		if(defined($opt_l)){print STDERR "$command\n";}
		if(system($command)==0){sleep(1);if(defined($opt_l)){print STDERR "OK\n";}}
		else{print STDERR "ERROR: Failed to $command\n";exit(1);}
	}
}
############################## throwJobs ##############################
sub throwJobs{
	my @variables=@_;
	my $url=shift(@variables);
	my $command=shift(@variables);
	my $processes=shift(@variables);
	my $server=$command->{$urls->{"daemon/server"}};
	my $qjob=$command->{$urls->{"daemon/qjob"}};
	my $qjobopt=$command->{$urls->{"daemon/qjob/opt"}};
	my $container=$command->{$urls->{"daemon/container"}};
	my $server=$command->{$urls->{"daemon/server"}};
	my $username=$command->{$urls->{"daemon/username"}};
	if(scalar(@variables)==0){return;}
	my ($fh,$path)=tempfile("bashXXXXXXXXXX",DIR=>"/tmp",SUFFIX=>".sh");
	my $basename=basename($path,".sh");
	my $stderr="/tmp/$basename.stderr";
	my $stdout="/tmp/$basename.stdout";
	if($qjob eq "sge"){
		print $fh "#\$ -e $stderr\n";
		print $fh "#\$ -o $stdout\n";
	}
	print $fh "export PATH=$exportpath\n";
	print $fh "function check() {\n";
	print $fh "file=\$1\n";
	print $fh "grep -E '^(completed|error)' \$file > /dev/null\n";
	print $fh "if [ \$? -eq 0 ]\n";
	print $fh "then\n";
	print $fh "return\n";
	print $fh "fi\n";
	print $fh "echo \"error\t\"`date +\%s` >> \$file\n";
	print $fh "}\n";
	my @ids=();
	foreach my $var(@variables){
		my $bashsrc=$var->{"bashsrc"};
		my $bashscp=$var->{"bashscp"};
		my $bashfile=$var->{"bashfile"};
		my $stdoutfile=$var->{"stdoutfile"};
		my $stderrfile=$var->{"stderrfile"};
		my $execid=$var->{"execid"};
		my $binddir=$var->{"binddir"};
		push(@ids,$execid);
		if(defined($container)){
			if($container=~/\.sif$/){
				print $fh "singularity \\\n";
				print $fh "  --silent \\\n";
				print $fh "  exec \\\n";
				print $fh "  --workdir=/root \\\n";
				print $fh "  --bind=$binddir:/root \\\n";
				print $fh "  $binddir/$container \\\n";
				print $fh "  /bin/bash $bashfile \\\n";
				print $fh "  > $stdoutfile \\\n";
				print $fh "  2> $stderrfile\n";
			}else{
				print $fh "docker \\\n";
				print $fh "  run \\\n";
				print $fh "  --rm \\\n";
				print $fh "  --workdir=/root \\\n";
				print $fh "  -v '$binddir:/root' \\\n";
				print $fh "  $container \\\n";
				print $fh "  /bin/bash $bashfile \\\n";
				print $fh "  > $stdoutfile \\\n";
				print $fh "  2> $stderrfile\n";
			}
		}else{
			print $fh "bash $bashfile \\\n";
			print $fh "  > $stdoutfile \\\n";
			print $fh "  2> $stderrfile\n";
		}
		if(defined($server)&&defined($username)){
			uploadIfNecessary($bashsrc,"$username\@$server:$bashscp");
			removeFiles($bashsrc);
		}
	}
	print $fh "if [ -e $stdout ] && [ ! -s $stdout ]; then\n";
	print $fh "rm $stdout\n";
	print $fh "fi\n";
	print $fh "if [ -e $stderr ] && [ ! -s $stderr ]; then\n";
	print $fh "rm $stderr\n";
	print $fh "fi\n";
	close($fh);
	if(defined($server)&&defined($username)){
		my $path2="$username\@$server:$path";
		uploadIfNecessary($path,$path2);
		$path=$path2;
	}
	my $date=getDate("/");
	my $time=getTime(":");
	if(defined($opt_l)){print STDERR "$date $time Submitting job ".join(",",@ids).":\t";}
	throwBashJob($path,$qjob,$qjobopt,$stdout,$stderr);
	foreach my $id(@ids){
		my ($writer,$tempfile)=tempfile();
		writeLog($id,$urls->{"daemon/execute"}."\tprocessed");
		my $logfile="$rootdir/$jobdir/$id.txt";
		my $processfile="$processdir/$id.txt";
		system("ln -s $logfile $processfile");
		my $logs={};
		my $reader=openFile($processfile);
		while(<$reader>){chomp;my ($key,$val)=split(/\t/);$logs->{$key}=$val;}
		close($reader);
		$processes->{$id}=$logs;
	}
}
############################## uploadIfNecessary ##############################
sub uploadIfNecessary{
	my $from=shift();
	my $to=shift();
	my $timeFrom=checkTimestamp($from);
	my $timeTo=checkTimestamp($to);
	if(!defined($timeTo)||$timeFrom>$timeTo){system("scp $from $to 2>&1 1>/dev/null");}
}
############################## which ##############################
sub which{
	my $cmd=shift();
	my $hash=shift();
	if(!defined($hash)){$hash={};}
	if(exists($hash->{$cmd})){return $hash->{$cmd};}
	my $server;
	my $command=$cmd;
	if($command=~/^(.+\@.+)\:(.+)$/){
		$server=$1;
		$command=$2;
	}
	my $result;
	if(defined($server)){
		open(CMD,"ssh $server 'which $command' 2>&1 |");
		while(<CMD>){chomp;if($_ ne ""){$result=$_;}}
		close(CMD);
	}else{
		open(CMD,"which $command 2>&1 |");
		while(<CMD>){chomp;if($_ ne ""){$result=$_;}}
		close(CMD);
	}
	$hash->{$cmd}=$result;
	return $result;
}
############################## writeLog ##############################
sub writeLog{
	my @lines=@_;
	my $execid=shift(@lines);
	my $dirname=substr($execid,1,8);
	my $logfile="$jobdir/$execid.txt";
	open(OUT,">>$logfile");
	foreach my $line(@lines){print OUT "$line\n";}
	close(OUT);
}
############################## writeScript ##############################
sub writeScript{
	my $url=shift();
	my $outdir=shift();
	my $commands=shift();
	my $command=loadCommandFromURL($url,$commands);
	my $basename=basename($url,".json");
	my $outfile="$outdir/$basename.sh";
	my @outs=();
	push(@outs,$outfile);
	open(OUT,">$outfile");
	foreach my $line(@{$command->{$urls->{"daemon/bash"}}}){
		$line=~s/\$workdir\///g;
		print OUT "$line\n";
	}
	close(OUT);
	if(exists($command->{$urls->{"daemon/script"}})){
		foreach my $script(@{$command->{$urls->{"daemon/script"}}}){
			my $path="$outdir/".$script->{$urls->{"daemon/script/name"}};
			$path=~s/\$workdir\///g;
			push(@outs,$path);
			open(OUT,">$path");
			foreach my $line(@{$script->{$urls->{"daemon/script/code"}}}){print OUT "$line\n";}
			close(OUT);
		}
	}
	return @outs;
}
