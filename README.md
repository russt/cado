cado
====
Cado is a mature and extensible code generation language that operates on standard templates with embedded macros. It is useful for generating source code and other related content (tests, documents, tools, configuations, etc.), deriving from a common project dictionary or nomenclature.

Cado can be used to generate large build systems or test suites.  It has been used to generate maven build systems with thousands of pom.xml files.  It has been used to convert large ant build systems to maven.  It can be used to refactor shell or csh scripts.  It can be used to document a complex tool chain, and interfaces seamlessly with the unix/linux shell.

You can easily add to cado by writing a special purpose subroutine in perl.  These operators are similar to the unix pipe semantics; i.e., they accept an input (content of a variable) and transform it to a new value.

Here is a very simple example:

    mystring = ABC
    mystring = $mystring:tolower:toupper

This converts the string to lowercase, and then back to uppercase.

Please see the *Cado Quick Reference* for a complete list of internal operators and constructs.
                    

System Requirements:
====================
* Perl 5.x - Cado is highly portable and will run on most versions of perl 5.

See Also:
=========
* The *Cado Quick Reference*: `tl/src/cmn/cado/cgdoc.txt`
* Help message:  `cado -help`
* Tar distributions:  <http://sourceforge.net/projects/cado/files>
* Cado is used to generate itself.  See `tl/src/cmn/cado/srcgen`
* See cado test suite for examples of individual features:  `tl/src/cmn/cado/regress/*.cg`

