# goblint-web
A webinterface for goblint

### Dependencies
Opa needs https://nodejs.org/.

xml to json converter (https://www.npmjs.com/package/xml-json). Because Opa is really bad at parsing xml (built-in parser but also own parsers produce stack overflows even for not very large files), xml is converted to json which is parsed by Opa.

    npm install xml-json -g
### How-To

    make run
and open
    
    http://localhost:8080

The goblint executable is expected here:

    ../analyzer/goblint
or change it in Model.upload_analysis (in src/model.opa)
