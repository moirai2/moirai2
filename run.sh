tmpdir="tmp/align_single.Gaf0_1zFu5"
stdoutfile="align_single.Gaf0_1zFu5.stdout"
basename="align_single.Gaf0_1zFu5"A

if [[ `grep  finish < $tmpdir/$stdoutfile` ]];then
echo Hello
#rm $tmpdir/$basename.Log.final.out $tmpdir/$basename.Log.progress.out $tmpdir/$basename.SJ.out.tab $tmpdir/$stderrfile $tmpdir/$stdoutfile
fi
