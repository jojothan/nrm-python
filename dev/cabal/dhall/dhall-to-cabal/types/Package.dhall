-- This file is auto-generated by dhall-to-cabal-meta. Look but don't touch (unless you want your edits to be over-written).
{ author :
    Text
, benchmarks :
    List { name : Text, benchmark : ./Config.dhall → ./Benchmark.dhall }
, bug-reports :
    Text
, build-type :
    Optional ./BuildType.dhall
, cabal-version :
    ./Version.dhall
, category :
    Text
, copyright :
    Text
, custom-setup :
    Optional ./SetupBuildInfo.dhall
, data-dir :
    Text
, data-files :
    List Text
, description :
    Text
, executables :
    List { name : Text, executable : ./Config.dhall → ./Executable.dhall }
, extra-doc-files :
    List Text
, extra-source-files :
    List Text
, extra-tmp-files :
    List Text
, flags :
    List ./Flag.dhall
, foreign-libraries :
    List { name : Text, foreign-lib : ./Config.dhall → ./ForeignLibrary.dhall }
, homepage :
    Text
, library :
    Optional (./Config.dhall → ./Library.dhall)
, license :
    ./License.dhall
, license-files :
    List Text
, maintainer :
    Text
, name :
    Text
, package-url :
    Text
, source-repos :
    List ./SourceRepo.dhall
, stability :
    Text
, sub-libraries :
    List { name : Text, library : ./Config.dhall → ./Library.dhall }
, synopsis :
    Text
, test-suites :
    List { name : Text, test-suite : ./Config.dhall → ./TestSuite.dhall }
, tested-with :
    List { compiler : ./Compiler.dhall, version : ./VersionRange.dhall }
, version :
    ./Version.dhall
, x-fields :
    List { _1 : Text, _2 : Text }
}