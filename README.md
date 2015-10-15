# goblint-web
A webinterface for goblint

### Dependencies
Opa needs https://nodejs.org/.

xml to json converter (https://www.npmjs.com/package/xml-json). Because Opa is really bad at parsing xml (built-in parser but also own parsers produce stack overflows even for not very large files), xml is converted to json which is parsed by Opa.
UPDATE: this issue seems to be related to an older version of nodejs I was testing with.

    npm install xml-json -g
### How-To

    make run
and open
    
    http://localhost:8080

The goblint executable path is passed via the command line, default value is:

    ../analyzer/goblint
Change it in Makefile if necessary.

### Make Targets

    make run
starts the webserver on localhost:8080.

    make test
does some tests (calls goblint-web with all files found in ../analyzer/tests/regression/ by default. You can change this filepath via command line)

    make debug file="<filepath>"
debug goblint-web with a single file. It will process this file and open a browser aftwards, showing the outcome, if successful.

### CommandLine Arguments

    ./goblint-web.exe --help
will show you all accepted command line arguments. Especially interesting are the ones in the section "Goblint Web parameters", the other ones are opalang options
