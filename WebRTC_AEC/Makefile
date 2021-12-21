TARGET = aec_test

CC = gcc

SRCDIR = src
OBJDIR = obj
BINDIR = bin

SRCS_c = $(wildcard $(SRCDIR)/*.c)

OBJS = $(SRCS_c:$(SRCDIR)/%.c=$(OBJDIR)/%_c.o)
rm = rm -f

CFLAGS = -Wall -g -O3 -lm


$(BINDIR)/$(TARGET): $(OBJS)
	$(CC) $(OBJS) $(CFLAGS) -o $@

$(OBJDIR)/%_c.o : $(SRCDIR)/%.c
	$(CC) $(CFLAGS) -c $< -o $@

$(OBJDIR)/%_cpp.o : $(SRCDIR)/%.cc
	$(CC) $(CFLAGS) -c $< -o $@

.PHONY: clean
clean:
	$(rm) $(OBJS)

.PHONY: remove
remove:
	$(rm) $(BINDIR)/$(TARGET)
