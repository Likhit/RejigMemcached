@if "%DEBUG%" == "" @echo off
@rem ##########################################################################
@rem
@rem  RejigCoordinator startup script for Windows
@rem
@rem ##########################################################################

@rem Set local scope for the variables with windows NT shell
if "%OS%"=="Windows_NT" setlocal

set DIRNAME=%~dp0
if "%DIRNAME%" == "" set DIRNAME=.
set APP_BASE_NAME=%~n0
set APP_HOME=%DIRNAME%..

@rem Add default JVM options here. You can also use JAVA_OPTS and REJIG_COORDINATOR_OPTS to pass JVM options to this script.
set DEFAULT_JVM_OPTS=

@rem Find java.exe
if defined JAVA_HOME goto findJavaFromJavaHome

set JAVA_EXE=java.exe
%JAVA_EXE% -version >NUL 2>&1
if "%ERRORLEVEL%" == "0" goto init

echo.
echo ERROR: JAVA_HOME is not set and no 'java' command could be found in your PATH.
echo.
echo Please set the JAVA_HOME variable in your environment to match the
echo location of your Java installation.

goto fail

:findJavaFromJavaHome
set JAVA_HOME=%JAVA_HOME:"=%
set JAVA_EXE=%JAVA_HOME%/bin/java.exe

if exist "%JAVA_EXE%" goto init

echo.
echo ERROR: JAVA_HOME is set to an invalid directory: %JAVA_HOME%
echo.
echo Please set the JAVA_HOME variable in your environment to match the
echo location of your Java installation.

goto fail

:init
@rem Get command-line arguments, handling Windows variants

if not "%OS%" == "Windows_NT" goto win9xME_args

:win9xME_args
@rem Slurp the command line arguments.
set CMD_LINE_ARGS=
set _SKIP=2

:win9xME_args_slurp
if "x%~1" == "x" goto execute

set CMD_LINE_ARGS=%*

:execute
@rem Setup the command line

set CLASSPATH=%APP_HOME%\lib\RejigCoordinator.jar;%APP_HOME%\lib\Memcached-Java-Client.jar;%APP_HOME%\lib\RejigInterface.jar;%APP_HOME%\lib\curator-x-async-4.0.1.jar;%APP_HOME%\lib\curator-recipes-4.0.1.jar;%APP_HOME%\lib\grpc-netty-shaded-1.16.1.jar;%APP_HOME%\lib\grpc-protobuf-1.16.1.jar;%APP_HOME%\lib\protobuf-java-3.6.1.jar;%APP_HOME%\lib\grpc-stub-1.16.1.jar;%APP_HOME%\lib\curator-framework-4.0.1.jar;%APP_HOME%\lib\grpc-protobuf-lite-1.16.1.jar;%APP_HOME%\lib\grpc-core-1.16.1.jar;%APP_HOME%\lib\curator-client-4.0.1.jar;%APP_HOME%\lib\guava-26.0-android.jar;%APP_HOME%\lib\proto-google-common-protos-1.0.0.jar;%APP_HOME%\lib\grpc-context-1.16.1.jar;%APP_HOME%\lib\gson-2.7.jar;%APP_HOME%\lib\opencensus-contrib-grpc-metrics-0.12.3.jar;%APP_HOME%\lib\opencensus-api-0.12.3.jar;%APP_HOME%\lib\error_prone_annotations-2.2.0.jar;%APP_HOME%\lib\jsr305-3.0.2.jar;%APP_HOME%\lib\animal-sniffer-annotations-1.17.jar;%APP_HOME%\lib\checker-compat-qual-2.5.2.jar;%APP_HOME%\lib\j2objc-annotations-1.1.jar;%APP_HOME%\lib\zookeeper-3.5.3-beta.jar;%APP_HOME%\lib\slf4j-api-1.7.6.jar;%APP_HOME%\lib\commons-cli-1.2.jar;%APP_HOME%\lib\log4j-1.2.17.jar;%APP_HOME%\lib\netty-3.10.5.Final.jar

@rem Execute RejigCoordinator
"%JAVA_EXE%" %DEFAULT_JVM_OPTS% %JAVA_OPTS% %REJIG_COORDINATOR_OPTS%  -classpath "%CLASSPATH%" edu.usc.cs550.rejig.coordinator.App %CMD_LINE_ARGS%

:end
@rem End local scope for the variables with windows NT shell
if "%ERRORLEVEL%"=="0" goto mainEnd

:fail
rem Set variable REJIG_COORDINATOR_EXIT_CONSOLE if you need the _script_ return code instead of
rem the _cmd.exe /c_ return code!
if  not "" == "%REJIG_COORDINATOR_EXIT_CONSOLE%" exit 1
exit /b 1

:mainEnd
if "%OS%"=="Windows_NT" endlocal

:omega
