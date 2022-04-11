#$ -i $id->message->$message
#$ -o $id->output->$output
#$-r output
#$ message=test
#$ output=test/$id.txt
echo "Hello $message">$output
