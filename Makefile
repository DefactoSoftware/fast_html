# SPDX-FileCopyrightText: 2017-2019 myhtmlex authors <https://github.com/Overbryd/myhtmlex>
# SPDX-FileCopyrightText: 2019-2022 Pleroma Authors <https://pleroma.social>
# SPDX-License-Identifier: LGPL-2.1-only

MIX = mix
CMAKE = cmake
CFLAGS ?= -g -O2 -pedantic -Wcomment -Wextra -Wno-old-style-declaration -Wall

# set erlang include path
ERLANG_PATH = $(shell erl -eval 'io:format("~s", [lists:concat([code:root_dir(), "/erts-", erlang:system_info(version)])])' -s init stop -noshell)
CNODE_CFLAGS += -I$(ERLANG_PATH)/include

# expecting myhtml as a submodule in c_src/
# that way we can pin a version and package the whole thing in hex
# hex does not allow for non-app related dependencies.
LXB_PATH = c_src/lexbor
LXB_AR = $(LXB_PATH)/liblexbor_static.a
LXB_CFLAGS  = -I$(LXB_PATH)/source
LXB_LDFLAGS = $(LXB_AR)

# C-Node
ERL_INTERFACE = $(wildcard $(ERLANG_PATH)/../lib/erl_interface-*)
CNODE_CFLAGS += -I$(ERL_INTERFACE)/include
CNODE_LDFLAGS += -L$(ERL_INTERFACE)/lib -lei -lpthread

.PHONY: all

all: priv/fasthtml_worker

$(LXB_AR): $(LXB_PATH)
	# Sadly, build components separately seems to sporadically fail
	cd $(LXB_PATH); \
		CFLAGS='$(CFLAGS)' \
		cmake -DLEXBOR_BUILD_SEPARATELY=OFF -DLEXBOR_BUILD_SHARED=OFF
	$(MAKE) -C $(LXB_PATH)

priv/fasthtml_worker: c_src/fasthtml_worker.c $(LXB_AR)
	mkdir -p priv
	$(CC) -std=c99 $(CFLAGS) $(CNODE_CFLAGS) $(LXB_CFLAGS) -o $@ $< $(LDFLAGS) $(CNODE_LDFLAGS) $(LXB_LDFLAGS)

clean: clean-myhtml
	$(RM) -r priv/myhtmlex*
	$(RM) priv/fasthtml_worker
	$(RM) myhtmlex-*.tar
	$(RM) -r package-test

clean-myhtml:
	$(MAKE) -C $(MYHTML_PATH) clean
