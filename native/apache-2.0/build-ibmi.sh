#!/bin/sh

# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Orchestrates setting up IBM i libraries/PFs required to build mod_jk.
# As the IBM i version of this does not use autotools, but some CL scripts,
# this is the bare minimum needed to get the scripts working on IBM i 7.2.
# Adapted from https://www.ibm.com/support/pages/node/6520356
LIB=MOD_JK

system crtlib "$LIB" "text('mod_jk Apache module')"
system crtsrcpf "$LIB/qsrvsrc" "text('mod_jk service program binding description')"
system crtsrcpf "$LIB/qclsrc" "text('mod_jk command language scripts')"
# XXX: Nowadays, you can compile service programs and CL source from IFS on
# newer versions of IBM i, in 7.3 and 7.4 respectively IIRC.
Rfile -wQ "$LIB/qsrvsrc(mod_jk)" << EOF
STRPGMEXP PGMLVL(*CURRENT)
    EXPORT SYMBOL("jk_module")
ENDPGMEXP
EOF
system cpyfrmstmf "fromstmf('bldjk72.qclsrc')" "tombr('/QSYS.LIB/$LIB.LIB/QCLSRC.FILE/BLDJK72.MBR')"
system crtclpgm "pgm($LIB/bldjk72)" "srcfile('$LIB/QCLSRC')" "text('mod_jk build program')" "tgtrls(*current)"
system call "$LIB/bldjk72"

# The document recommends copying into QHTTPSVR (probably unnecessary) and
# adjusting permissions so QTMHHTTP (web server user) can load it (good idea)
