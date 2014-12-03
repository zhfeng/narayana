if not defined WORKSPACE (call:fail_build & exit -1)
for /f "usebackq delims=<,> tokens=3" %%i in (`findstr "jboss-as.version" pom.xml`) do @set WILDFLY_MASTER_VERSION=%%i
echo "Set WILDFLY_MASTER_VERSION=%WILDFLY_MASTER_VERSION%"

echo "Building BlackTie
cd blacktie
rmdir wildfly-%WILDFLY_MASTER_VERSION% /s /q
mkdir wildfly-%WILDFLY_MASTER_VERSION%
xcopy ..\jboss-as\build\target\wildfly-%WILDFLY_MASTER_VERSION% wildfly-%WILDFLY_MASTER_VERSION% /S
set JBOSS_HOME=%CD%\wildfly-%WILDFLY_MASTER_VERSION%\
unzip wildfly-blacktie\build\target\wildfly-blacktie-build-5.0.4.Final-SNAPSHOT-bin.zip -d %JBOSS_HOME%
cd ..\

set NOPAUSE=true

rem SHUTDOWN ANY PREVIOUS BUILD REMNANTS
FOR /F "usebackq tokens=5" %%i in (`"netstat -ano|findstr 9990.*LISTENING"`) DO taskkill /F /PID %%i
tasklist
taskkill /F /IM mspdbsrv.exe
taskkill /F /IM testsuite.exe
taskkill /F /IM server.exe
taskkill /F /IM client.exe
taskkill /F /IM cs.exe
taskkill /F /IM java.exe
tasklist

if not defined JBOSSAS_IP_ADDR echo "JBOSSAS_IP_ADDR not set" & for /f "delims=" %%a in ('hostname') do @set JBOSSAS_IP_ADDR=%%a

rem INITIALIZE JBOSS
call ant -f blacktie\scripts\hudson\initializeJBoss.xml -DJBOSS_HOME=%WORKSPACE%\blacktie\wildfly-%WILDFLY_MASTER_VERSION% initializeJBoss -debug || (call:fail_build & exit -1)

set JBOSS_HOME=%WORKSPACE%\blacktie\wildfly-%WILDFLY_MASTER_VERSION%

rem START JBOSS
rem set JAVA_OPTS="%JAVA_OPTS% -Xmx1024m -XX:MaxPermSize=512m"
start /B %JBOSS_HOME%\bin\standalone.bat -c standalone-blacktie.xml -Djboss.bind.address=%JBOSSAS_IP_ADDR% -Djboss.bind.address.unsecure=%JBOSSAS_IP_ADDR% -Djboss.bind.address.management=%JBOSSAS_IP_ADDR%
echo "Started server"
@ping 127.0.0.1 -n 20 -w 1000 > nul

rem BUILD BLACKTIE
call build.bat -f blacktie\blacktie-admin-services\ear\pom.xml clean install "-Djbossas.ip.addr=%JBOSSAS_IP_ADDR%"
call build.bat -f blacktie\btadmin\pom.xml clean install "-Djbossas.ip.addr=%JBOSSAS_IP_ADDR%" "-Dtest=AdvertiseTest"|| (call:fail_build & exit -1)

rem SHUTDOWN ANY PREVIOUS BUILD REMNANTS
tasklist & FOR /F "usebackq tokens=5" %%i in (`"netstat -ano|findstr 9990.*LISTENING"`) DO taskkill /F /PID %%i
echo "Finished build"

call:comment_on_pull "BLACKTIE profile tests passed on Windows - Job complete %BUILD_URL%"

rem ------------------------------------------------------
rem -                 Functions below                    -
rem ------------------------------------------------------

goto:eof

:fail_build
  call:comment_on_pull "Build failed %BUILD_URL%"
  tasklist & FOR /F "usebackq tokens=5" %%i in (`"netstat -ano|findstr 9990.*LISTENING"`) DO taskkill /F /PID %%i
  tasklist
  taskkill /F /IM mspdbsrv.exe
  taskkill /F /IM testsuite.exe
  taskkill /F /IM server.exe
  taskkill /F /IM client.exe
  taskkill /F /IM cs.exe
  taskkill /F /IM java.exe
  tasklist
  exit -1
goto:eof

:comment_on_pull
   if not "%COMMENT_ON_PULL%"=="1" goto:eof

   for /f "tokens=1,2,3,4 delims=/" %%a in ("%GIT_BRANCH%") do set IS_PULL=%%b&set PULL_NUM=%%c
   if not "%IS_PULL%"=="pull" goto:eof
   
   curl -k -d "{ \"body\": \"%~1\" }" -ujbosstm-bot:%BOT_PASSWORD% https://api.github.com/repos/%GIT_ACCOUNT%/%GIT_REPO%/issues/%PULL_NUM%/comments

goto:eof
