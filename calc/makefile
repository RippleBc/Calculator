#获取当前目录下的c文件集
CUR_SOURCE=${wildcard *.c}
#将对应的c文件名转为o文件
CUR_OBJS=${patsubst %.c, $(OBJS_DIR)/%.o, $(notdir $(CUR_SOURCE))}

all:$(CUR_OBJS)

$(OBJS_DIR)/%.o:%.c
	$(CC) $(CFLAGS) -o $@ -c $<
