# Copyright 2018 Oticon A/S
# Copyright 2023 Nordic Semiconductor ASA
# SPDX-License-Identifier: Apache-2.0

OBJS=$(abspath $(addprefix $(COMPONENT_OUTPUT_DIR)/,${SRCS:.c=.${VARIANT}.o}))
LIBFILE=${LIB_NAME}.a
VERSION_FILE:=${LIB_NAME}.version

all: compile

DEPENDFILES:=$(addsuffix .d,$(basename ${OBJS})) 

-include ${DEPENDFILES}

always_run_this_target: 
#phony target to trigger the rerun of the make of each library, but ensure that make checks if the library was regenerated (so it doesnt relink the binary if it wasnt)
# we could do like in the root Makefile, and just go first over all the libraries makefiles we may need instead, but this is slighly more efficient (although more messy)

.PHONY: all install compile lib clean clean_all ${DEPENDFILES} always_run_this_target version
#setting the dependencies as phony targets will actually speed up things.. (otherwise make will check if there is implicit rules to remake them)

compile: $(COMPONENT_OUTPUT_DIR)/${LIBFILE}

$(COMPONENT_OUTPUT_DIR):
	@mkdir -p $(COMPONENT_OUTPUT_DIR)

$(COMPONENT_OUTPUT_DIR)/%.${VARIANT}.o: %.c
	@if [ ! -d $(dir $@) ]; then mkdir -p $(dir $@); fi
	@${CC} ${CPPFLAGS} ${CFLAGS} ${COVERAGE} -c $< -o $@

%.c: ;
%.h: ;

$(COMPONENT_OUTPUT_DIR)/${LIBFILE}: $(COMPONENT_OUTPUT_DIR) ${OBJS} ${A_LIBS}
	@rm $(COMPONENT_OUTPUT_DIR)/${LIBFILE} &> /dev/null ; true
	@${AR} -cr $(COMPONENT_OUTPUT_DIR)/${LIBFILE} ${OBJS} ${A_LIBS}

lib :compile

${A_LIBS}:;
	$(error Required library ($@) not found. Run top level make to build all dependencies in order)

clean:
	@echo "Deleting intermediate compilation results"
	@find $(COMPONENT_OUTPUT_DIR) -name "*.o" -or -name "*.so" -or -name "*.a" -or -name "*.d" | xargs rm -f
	@rm $(COMPONENT_OUTPUT_DIR)/${LIBFILE} &> /dev/null ; true

clean_coverage:
	@find $(COMPONENT_OUTPUT_DIR) -name "*.gcda" -or -name "*.gcno" | xargs rm -f ; true

clean_all: clean clean_coverage

${BSIM_LIBS_DIR}/${VERSION_FILE}: version
	@if [[ -f "$<" ]]; then\
	  cp $< $@; \
	else \
	  echo "unknown" > $@; \
	fi

${BSIM_LIBS_DIR}/% : $(COMPONENT_OUTPUT_DIR)/%
	@cp $< $@ 

install: ${BSIM_LIBS_DIR}/${LIBFILE} ${BSIM_LIBS_DIR}/${VERSION_FILE}

# Let's explicitly tell make there is rules to make these make files: 
make_inc/pre.mk: ;
make_inc/common_post.mk: ;
${BSIM_BASE_PATH}/common/pre.make.inc: ;
