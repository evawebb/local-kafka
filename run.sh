if [ "$1" == 'single' ]; then
  ./run-single-container.sh "$2"
elif [ "$1" == 'multiple' ]; then
  ./run-multiple-containers.sh "$2"
else
  ./run-multiple-containers.sh "$1"
fi
