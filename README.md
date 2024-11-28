# Batch conversion of word files to dtbook (on windows)

This repo contains a simple script for windows that
takes all docx file from the "in" folder, converts them to dtbook using an embedded DAISY pipeline 2, applies a repair operation ont them and move the result to the "out" folder.

To start using it, just put your docx file in the "in" folder and run the script in a powershell terminal with `& .\run.ps1`.

## Update the pipeline

If you want to rebuild the embedded pipeline, you will need to do the following command

```
git submodule update --init --recurse
.\engine\make.exe clean
.\engine\make.exe
```