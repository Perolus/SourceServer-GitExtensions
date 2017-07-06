@echo off

if ()==(%1) exit /b
if ()==(%2) exit /b
if ()==(%3) exit /b
if ()==(%4) exit /b
if ()==(%5) exit /b

setlocal
set GIT_NODE_URL="%~1"
set GIT_NODE_URL=%GIT_NODE_URL: (fetch)=%
set GIT_BRANCH="%~2"
set GIT_WORKING_DIR="%~3"
set GIT_OBJ_ID="%~4"
set GIT_CONTENTS_OUTPUT="%~5"

echo "GIT_NODE_URL: %GIT_NODE_URL%"
echo "GIT_BRANCH: %GIT_BRANCH%"
echo "GIT_WORKING_DIR: %GIT_WORKING_DIR%"
echo "GIT_OBJ_ID: %GIT_OBJ_ID%"
echo "GIT_CONTENTS_OUTPUT: %GIT_CONTENTS_OUTPUT%"

if exist %GIT_WORKING_DIR% goto update

md %GIT_WORKING_DIR%
git --git-dir=%GIT_WORKING_DIR% init
git --git-dir=%GIT_WORKING_DIR% fetch %GIT_NODE_URL%
goto show

:update
for /f "usebackq delims=" %%i in (`git --no-pager --git-dir=%%GIT_WORKING_DIR%% show %%GIT_OBJ_ID%%`) do ( goto show )
echo *Updating...*
git --git-dir=%GIT_WORKING_DIR% fetch %GIT_NODE_URL%

:show
if not exist %~dp4 mkdir %~dp4
git --no-pager --git-dir=%GIT_WORKING_DIR% show %GIT_OBJ_ID% > %GIT_CONTENTS_OUTPUT%

:cleanup
endlocal
