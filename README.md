# OpenSoldat Scripting
Repository for storing [OpenSoldat](https://github.com/opensoldat/opensoldat) game server scripts. The reason for placing server scripts here is to make writing the scripts in different language more convenient later by using this repository. I am not the only author of the files, some of them are the property of their respective owners.

## Running
Requires installing [OpenSoldat Server](https://wiki.soldat.pl/index.php/Server) to use them. After installing, upload the files you want to the `scripts` folder. Every script requires its own folder to work, which looks like this:

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
