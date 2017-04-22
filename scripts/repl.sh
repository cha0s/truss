tst=`which rlwrap`
if [ -z "$tst" ]
then
      echo "You must install `rlwrap` to use this script"
else
      rlwrap -C qmp socat STDIO UNIX:packages/truss-repl/socket
fi

