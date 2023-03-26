##
# 显示指定JVM进程自启动以来占用CPU时间最高的前几个线程
# 显示指定JVM进程当前占用cpu最多的前几个线程

#!/bin/bash
source /etc/profile
pid=$1
mode=$2 # history 历史 current 当前值
if [ $mode == "h" ]; then
  top -H -p $pid -o TIME+ -n 1 >top.txt
fi
if [ $mode == "c" ]; then
  top -H -p $pid -o %CPU -n 1 >top.txt
fi

if [ ! -f JStack_${pid}.log ]; then
  jstack $pid >JStack_${pid}.log
fi

tail -n +8 top.txt | while read line; do
  firstCol=$(echo $line | awk -F ' ' '{print $1}')
  ## 防止出现第一列为空列 不是线程id
  if [[ ! ${firstCol} =~ (.?)[0-9]$ ]]; then
    threadId=$(echo $line | awk -F ' ' '{print $2}' | xargs printf '%x\n')
    if [ $mode == "h" ]; then
      metric=$(echo $line | awk -F ' ' '{print $12}')
    fi
    if [ $mode == "c" ]; then
      metric=$(echo $line | awk -F ' ' '{print $10}')
    fi
  else
    threadId=$(echo $firstCol | grep -P -o "[0-9]{2,}" | xargs printf '%x\n')
    if [ $mode == "h" ]; then
      metric=$(echo $line | awk -F ' ' '{print $11}')
    fi
    if [ $mode == "c" ]; then
      metric=$(echo $line | awk -F ' ' '{print $9}')
    fi
  fi
  threadInfo=$(grep 0x${threadId} JStack_${pid}.log)
  echo ${metric}" "${threadInfo}
done

