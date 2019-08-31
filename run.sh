#!/bin/bash
#
# \description  Execution on multiple networks
#
# \author Artem V L <artem@exascale.info>  https://exascale.info

MODEL=line  # line, deepwalk;  node2vec is not scalable  
DIMS=128
#NETS="blogcatalog dblp homo wiki youtube"
NETS="blogcatalog dblp homo wiki"
#NETS="dblp"
#NETS=youtube
WORKERS=1  # 16
INSTS=0  # The number of network instances
RESTRACER=./exectime  # time
LOGDIR=embeds/logs
mkdir -p $LOGDIR

USAGE="$0 -h | [-m <model>=${NODEL}] [-d <dimensions>=${DIMS}] [-w <workers>=${WORKERS}] [--instances <number>]
  -m,--model  - underlyting graph-embedding model: line deepwalk node2vec. Note: node2vec is not scalable
  -d,--dims  - required number of dimensions in the embedding model
  -w,--workers  - maximal number of workers (parallel thread). Note: deepwalk training can be failed on non-small datasets with small number of workers
  --instances  - the number of network instances
  -h,--help  - help, show this usage description

  Examples:
  \$ $0 -d 128 -m line -w 4
"

while [ $1 ]; do
	case $1 in
	-h|--help)
		# Use defaults for the remained parameters
		echo -e $USAGE  # -e to interpret '\n'
		exit 0
		;;
	-d|--dims)
		if [ "${2::1}" == "-" ]; then
			echo "ERROR, invalid argument value of $1: $2"
			exit 1
		fi
		DIMS=$2
		echo "Set $1: $2"
		shift 2
		;;
	-m|--model)
		if [ "${2::1}" == "-" ]; then
			echo "ERROR, invalid argument value of $1: $2"
			exit 1
		fi
		MODEL=$2
		echo "Set $1: $2"
		shift 2
		;;
	-w|--workers)
		if [ "${2::1}" == "-" ]; then
			echo "ERROR, invalid argument value of $1: $2"
			exit 1
		fi
		WORKERS=$2
		echo "Set $1: $2"
		shift 2
		;;
	--instances)
		if [ "${2::1}" == "-" ]; then
			echo "ERROR, invalid argument value of $1: $2"
			exit 1
		fi
		INSTS=$2
		echo "Set $1: $2"
		shift 2
		;;
	*)
		printf "Error: Invalid option specified: $1 $2 ...\n\n$USAGE"
		exit 1
		;;
	esac
done

echo "Starting the training on `echo $NETS | wc -w` networks..."
if [ "$INSTS" -ge "1" ]; then
	for NET in $NETS; do
		for N in $(seq $INSTS); do
			echo "Starting the training on ${NET}${N}"
			$RESTRACER python3 src/harp.py --workers $WORKERS --sfdp-path bin/sfdp_linux --input graphs/${NET}${N}.mat --model ${MODEL} --representation-size ${DIMS} --output embeds/embs_harp-${MODEL}_${NET}${N}_${DIMS}.mat > "$LOGDIR/harp-${MODEL}_${NET}${N}_${DIMS}.log" 2> "$LOGDIR/harp-${MODEL}_${NET}${N}_${DIMS}.err"
		done
	done
else
	for NET in $NETS; do
		$RESTRACER python3 src/harp.py --workers $WORKERS --sfdp-path bin/sfdp_linux --input graphs/${NET}.mat --model ${MODEL} --representation-size ${DIMS} --output embeds/embs_harp-${MODEL}_${NET}_${DIMS}.mat > "$LOGDIR/harp-${MODEL}_${NET}_${DIMS}.log" 2> "$LOGDIR/harp-${MODEL}_${NET}_${DIMS}.err" &
	done
fi
# ./exectime python3 src/harp.py --workers 16  --sfdp-path bin/sfdp_linux --input graphs/youtube.mat --model line --representation-size 256 --output embeds/embs_harp-line_youtube_256.mat > embs/logs/harp-line_youtube_256.log 2> embs/logs/harp-line_youtube_256.err

