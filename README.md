# Premake-4.x with Embarcadero RAD Studio support

## Summary

* Generates groupproj/cbproj for RAD Studio.
* Supports RAD Studio 10-11, XE-XE3, 2010.
   * XE4-XE8 are omitted now, but almost all difference is generated ProductVersion number.
     * Most of codes are developped in 2012(XE3 era. please check "author date" with git log), I've just added 10 Settle .. 11 Alexandria support.
* Supports Win32/Win64 architecture only.
* If you choose WindowedApp, generates VCL application cbproj.
* No vpath, Native support.
* No unit tests included.

### Supported Actions for RadStudio

Actions added to original prameke4 is below(extracted from `premake4 --help`).

```txt
 rs100             Generate Embarcadero RAD Studio 10 Seattle project files
 rs101             Generate Embarcadero RAD Studio 10.1 Berlin project files
 rs102             Generate Embarcadero RAD Studio 10.2 Tokyo project files
 rs103             Generate Embarcadero RAD Studio 10.3 Rio project files
 rs104             Generate Embarcadero RAD Studio 10.4 Sydney project files
 rs110             Generate Embarcadero RAD Studio 11 Alexandria project files
 rs2010            Generate Embarcadero RAD Studio 2010 project files
 rsxe              Generate Embarcadero RAD Studio XE project files
 rsxe2             Generate Embarcadero RAD Studio XE2 project files
 rsxe3             Generate Embarcadero RAD Studio XE3 project files
```

## Additonal options for RadStudio support

### Bcc_UseNewCompiler flag

If specified, Win32 compiler use new clang based compiler.

```lua
configuration { "rs*", "x32" }
    flags { "BccUseNewCompiler" }
```

### bcc_disable_warnings

* Works with classic Win32 comipler.
* Specify warnings by command line option's id.

```lua
configuration { "rs*", "x32" }
  bcc_disable_warnings {
    "whid", -- W8022: 'function1' hides virtual function 'function2' (-w-hid)
    "wccc", -- W8008: Condition is always true OR Condition is always false (-w-ccc)
    "wpch", -- W8058: Cannot create pre-compiled header 'reason' (-w-pch)
    "wpar", -- W8057: Parameter 'parameter' is never used (-w-par)
    "wrch", -- W8066: Unreachable code (-w-rch)
    "wpia", -- W8060: Possibly incorrect assignment (-w-pia)
    "wmls", -- W8104: Local Static with constructor dangerous for multi-threaded apps (-w-mls)
    "waus", -- W8004: 'identifier' is assigned a value that is never used (-w-aus)
  }    
```

### bcc_clang_options

* Works with CLANG based compilers.
* Specify additonal command line options passed to compiler.
* See also
  * [Errors and Warnings of Clang\-enhanced C\+\+ Compilers \- RAD Studio](https://docwiki.embarcadero.com/RADStudio/Alexandria/en/Errors_and_Warnings_of_Clang-enhanced_C%2B%2B_Compilers)

```lua
configuration { "rs*", "x64" }    
  -- 
  bcc_clang_options {
    "-fdiagnostics-show-option",
    "-Wno-deprecated-writable-strings",
  }
```

## How to develop, debug

* Build debug version of premake4 and use /scripts option or set PREMAKE_PATH.
* Please see below
  * https://web.archive.org/web/20161011071817/http://industriousone.com/building-premake

