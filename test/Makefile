# Aggregate makefile that runs all testbenches

TESTED_MODULES=serial_mul serial_div serial_muldiv prog_if

TARGETS_ALL=$(addprefix all-, $(TESTED_MODULES))
TARGETS_CLEAN=$(addprefix clean-, $(TESTED_MODULES))

.PHONY: all $(TARGETS_ALL) clean $(TARGETS_CLEAN)

all: $(TARGETS_ALL)
	$(MAKE) -f whole_design.mk all

clean: $(TARGETS_CLEAN)
	$(MAKE) -f whole_design.mk clean

$(TARGETS_ALL): all-%:
	$(MAKE) -C module_tests/$* all

$(TARGETS_CLEAN): clean-%:
	$(MAKE) -C module_tests/$* clean
