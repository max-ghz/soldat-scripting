# Soldat Scripting
Repository for storing [Soldat](https://github.com/opensoldat/opensoldat) game server scripts for in-game servers. The reason for placing server scripts here is to make rewriting into a modern language more convenient later by using this repository. I am not the only author of the files, some of them are the property of their respective owners.

## Running
To use these in Soldat, it requires installing Soldat [server](https://wiki.soldat.pl/index.php/Server) to use them. After installing, upload the files you want to the `scripts` folder. Every script requires its own folder to work, which looks like this:

    objects
    scenery-gfx
    scripts
    ├── folder
    │   ├── example.pas
    │   └── Includes.txt
    └── folder2
        ├── example2.pas
        └── config.ini

To use files that have a database you will need an external library [libdb](https://github.com/XvayS/libdb) created for OpenSoldat dedicated servers.
