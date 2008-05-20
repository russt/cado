How to update maven2 pom.xml and settings.xml generators:

1)  codegen -u  top.cg
2)  codegen -u  install.cg

#to install new libs for distribution:
3)  cd maven2; makedrv -c mmf -C

note that each library here is installed separately:

    maven2/make.mmf
    maven/make.mmf
    xml/make.mmf

both maven 1.x and maven2 projects use the xml lib.

RT 2/28/08
