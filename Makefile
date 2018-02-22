PROJECT=read-nvml-clocks-pci
CC=nvcc
CXX=nvcc
RM=rm -f
CPPFLAGS=-gencode arch=compute_30,code=compute_30
LDFLAGS=
LDLIBS=-lnvidia-ml
IDIR=

SRCS=$(PROJECT).cu
OBJS=$(subst .cu,.o,$(SRCS))

all: $(PROJECT)

$(PROJECT): $(OBJS)
	$(CXX) $(CPPFLAGS) $(LDFLAGS) -o $@ $^ $(LDLIBS)

%.o: %.cu
	$(CXX) $(CPPFLAGS) $(IDIR) -c -o $@ $<

clean:
	$(RM) $(OBJS)
